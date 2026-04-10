const fs = require('fs');
const path = require('path');

// Create the missing migration file
const migrationDir = '/opt/planka/server/db/migrations';
const migrationFile = path.join(migrationDir, '20260312000000_add_ability_to_display_card_ages.js');

// Ensure migration directory exists
if (!fs.existsSync(migrationDir)) {
    fs.mkdirSync(migrationDir, { recursive: true });
}

// Create the missing migration file
const migrationContent = `'use strict';

exports.up = function(knex) {
    return knex.schema.table('cards', function(table) {
        table.boolean('displayCardAges').defaultTo(false);
    });
};

exports.down = function(knex) {
    return knex.schema.table('cards', function(table) {
        table.dropColumn('displayCardAges');
    });
};
`;

fs.writeFileSync(migrationFile, migrationContent);
console.log('Created missing migration file:', migrationFile);
