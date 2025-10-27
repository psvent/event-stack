Moodle local plugins (development workspace)

This directory contains Moodle plugins intended to be mounted into the Moodle app for local development.

Quick start
- Create or use an existing plugin inside this folder, for example: packages/moodle-plugins/eventstack
- Mount it into the running Moodle instance using the helper command:
  ddev -s moodle install-moodle-plugin ../packages/moodle-plugins/eventstack
- After restart, the plugin will be available under apps/moodle/local/eventstack inside the web container and in your Moodle site.

Notes
- This repo includes a barebones local plugin at packages/moodle-plugins/eventstack to use as a template.
- You can duplicate it and rename all occurrences of "eventstack" and "local_eventstack" to your desired plugin name.
