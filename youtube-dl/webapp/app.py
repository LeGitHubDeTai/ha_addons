import os
import subprocess
import logging
import threading
import time
import signal
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DOWNLOAD_DIR = os.environ.get('YTDLP_DOWNLOAD_DIR', '/media/youtube-dl')
CONFIG_DIR = os.environ.get('YTDLP_CONFIG_DIR', '/share/youtube-dl')
MAX_PARALLEL = int(os.environ.get('YTDLP_MAX_PARALLEL', '3'))
os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(CONFIG_DIR, exist_ok=True)

active_downloads = {}
download_lock = threading.Lock()

@app.route('/')
def index():
    files = os.listdir(DOWNLOAD_DIR) if os.path.isdir(DOWNLOAD_DIR) else []
    files = [f for f in files if os.path.isfile(os.path.join(DOWNLOAD_DIR, f))]
    return render_template('index.html', files=files, download_dir=DOWNLOAD_DIR, active=active_downloads)

@app.route('/download', methods=['POST'])
def download():
    url = request.form.get('url', '').strip()
    if not url:
        return jsonify({'error': 'URL vide'}), 400

    format_choice = request.form.get('format', 'best')
    if format_choice == 'best':
        fmt = 'bestvideo+bestaudio/best'
    elif format_choice == 'mp4':
        fmt = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'
    elif format_choice == 'audio':
        fmt = 'bestaudio/best'
    else:
        fmt = format_choice

    video_id = str(int(time.time() * 1000))
    task = {
        'id': video_id,
        'url': url,
        'status': 'downloading',
        'progress': 0,
        'format': format_choice,
        'started_at': time.strftime('%Y-%m-%d %H:%M:%S'),
    }
    with download_lock:
        active_downloads[video_id] = task

    def run_download():
        try:
            cmd = ['yt-dlp', '--no-warnings', '-o', os.path.join(DOWNLOAD_DIR, '%(title)s.%(ext)s'), '-f', fmt, url]
            logger.info(f"Lancement yt-dlp: {' '.join(cmd)}")
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            with download_lock:
                if video_id in active_downloads:
                    active_downloads[video_id]['pid'] = proc.pid
            proc.wait()
            with download_lock:
                if video_id in active_downloads:
                    active_downloads[video_id]['status'] = 'completed'
                    active_downloads[video_id]['progress'] = 100
            logger.info(f"Téléchargement terminé: {url}")
        except Exception as e:
            with download_lock:
                if video_id in active_downloads:
                    active_downloads[video_id]['status'] = 'error'
                    active_downloads[video_id]['error'] = str(e)
            logger.error(f"Erreur téléchargement: {e}")

    t = threading.Thread(target=run_download, daemon=True)
    t.start()
    return jsonify({'id': video_id, 'status': 'downloading'})

@app.route('/status/<video_id>')
def status(video_id):
    with download_lock:
        task = active_downloads.get(video_id, {'status': 'unknown'})
    return jsonify(task)

@app.route('/active')
def active():
    with download_lock:
        tasks = dict(active_downloads)
    return jsonify(tasks)

@app.route('/cancel/<video_id>', methods=['POST'])
def cancel(video_id):
    with download_lock:
        task = active_downloads.get(video_id)
        if task and task.get('pid'):
            try:
                os.kill(task['pid'], signal.SIGTERM)
            except Exception:
                pass
        if video_id in active_downloads:
            active_downloads[video_id]['status'] = 'cancelled'
    return jsonify({'status': 'cancelled'})

@app.route('/files')
def files():
    file_list = os.listdir(DOWNLOAD_DIR) if os.path.isdir(DOWNLOAD_DIR) else []
    file_list = [f for f in file_list if os.path.isfile(os.path.join(DOWNLOAD_DIR, f))]
    return jsonify({'files': sorted(file_list, reverse=True)})

@app.route('/delete/<filename>', methods=['POST'])
def delete(filename):
    filepath = os.path.join(DOWNLOAD_DIR, filename)
    if os.path.exists(filepath):
        os.remove(filepath)
        return jsonify({'status': 'deleted'})
    return jsonify({'error': 'Fichier non trouvé'}), 404

@app.route('/config')
def config():
    yt_cfg = os.path.join(CONFIG_DIR, 'yt-dlp.conf')
    config_data = {}
    if os.path.exists(yt_cfg):
        with open(yt_cfg, 'r') as f:
            for line in f:
                line = line.strip()
                if '=' in line and not line.startswith('#'):
                    key, val = line.split('=', 1)
                    config_data[key.strip()] = val.strip()
    return jsonify(config_data)

@app.route('/update_config', methods=['POST'])
def update_config():
    data = request.json
    yt_cfg = os.path.join(CONFIG_DIR, 'yt-dlp.conf')
    with open(yt_cfg, 'w') as f:
        for key, val in data.items():
            f.write(f"{key}={val}\n")
    return jsonify({'status': 'saved'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)