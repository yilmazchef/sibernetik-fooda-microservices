
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

define('DB_NAME', resta);
define('DB_USER', resta);
define('DB_PASSWORD', resta);
define('DB_HOST', db-resta);
define('DB_CHARSET', utf8mb4);
define('DB_PORT', 3306);
define('DB_PREFIX', getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_');

/** Absolute path to the WordPress directory. */

if ( !defined('ABSPATH') )

define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */

require_once(ABSPATH . 'wp-settings.php');


