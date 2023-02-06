
<?php

/**

 * The base configuration for WordPress

 *

 * The wp-config.php creation script uses this file during the

 * installation. You don't have to use the web site, you can

 * copy this file to "wp-config.php" and fill in the values.

 *

 * This file contains the following configurations:

 *

 * * MySQL settings

 * * Secret keys

 * * Database table prefix

 * * ABSPATH

 *

 * @link https://wordpress.org/support/article/editing-wp-config-php/

 *

 * @package WordPress

 */

// ** MySQL settings - You can get this info from your web host ** //

/** The name of the database for WordPress */

define('DB_NAME', fooda);
define('DB_USER', fooda);
define('DB_PASSWORD', fooda);
define('DB_HOST', db-fooda);
define('DB_CHARSET', utf8mb4);
define('DB_PORT', 3306);
define('DB_PREFIX', getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_');

/** Website settings */

define('WP_HOME', getenv('WORDPRESS_HOME') ?: 'http://localhost');
define('WP_SITEURL', getenv('WORDPRESS_SITEURL') ?: 'http://localhost');
define('WP_CONTENT_DIR', getenv('WORDPRESS_CONTENT_DIR') ?: '/var/www/html/wp-content');
define('WP_CONTENT_URL', getenv('WORDPRESS_CONTENT_URL') ?: 'http://localhost/wp-content');
define('WP_DEFAULT_THEME', getenv('WORDPRESS_DEFAULT_THEME') ?: 'twentyseventeen');
define('WP_DEBUG', getenv('WORDPRESS_DEBUG') ?: false);
define('WP_DEBUG_LOG', getenv('WORDPRESS_DEBUG_LOG') ?: false);
define('WP_DEBUG_DISPLAY', getenv('WORDPRESS_DEBUG_DISPLAY') ?: false);


/** Custom settings */

define('AUTOMATIC_UPDATER_DISABLED', getenv('WORDPRESS_AUTOMATIC_UPDATER_DISABLED') ?: true);
define('DISABLE_WP_CRON', getenv('WORDPRESS_DISABLE_WP_CRON') ?: true);
define('DISALLOW_FILE_EDIT', getenv('WORDPRESS_DISALLOW_FILE_EDIT') ?: true);
define('DISALLOW_FILE_MODS', getenv('WORDPRESS_DISALLOW_FILE_MODS') ?: true);
define('FORCE_SSL_ADMIN', getenv('WORDPRESS_FORCE_SSL_ADMIN') ?: false);
define('WP_ALLOW_MULTISITE', getenv('WORDPRESS_ALLOW_MULTISITE') ?: false);
define('WP_AUTO_UPDATE_CORE', getenv('WORDPRESS_AUTO_UPDATE_CORE') ?: false);
define('WP_CACHE', getenv('WORDPRESS_CACHE') ?: false);
define('WP_CRON_LOCK_TIMEOUT', getenv('WORDPRESS_CRON_LOCK_TIMEOUT') ?: 60);
define('WP_POST_REVISIONS', getenv('WORDPRESS_POST_REVISIONS') ?: 3);

/** Absolute path to the WordPress directory. */

if ( !defined('ABSPATH') )

define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */

require_once(ABSPATH . 'wp-settings.php');


