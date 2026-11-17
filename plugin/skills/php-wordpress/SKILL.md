---
name: php-wordpress
description: Use for PHP and WordPress work: themes, plugins, custom CRM/admin tools, REST endpoints, WP-CLI, nginx/PHP-FPM hosting, releases and WordPress security and performance.
---
# PHP and WordPress

## Inspect first
Plugin or theme? Minimum WordPress and PHP versions (plugin header `Requires PHP`, `Requires at least`), coding standard in use (WordPress Coding Standards vs PSR-12), build tooling (Composer, npm), text domain, prefix, and how releases are packaged. Match existing conventions.

## Security (most important)
- **Escape late, sanitise early**: `esc_html`, `esc_attr`, `esc_url`, `wp_kses_post` on output; `sanitize_text_field`, `absint`, `wp_unslash` on input.
- **Nonces and capabilities** on every state-changing action: `check_admin_referer`/`wp_verify_nonce` and `current_user_can`. REST routes need a real `permission_callback` (never `__return_true` for private data) and `args` validation/sanitise callbacks. AJAX handlers: separate `wp_ajax_` and `wp_ajax_nopriv_` deliberately.
- **Database**: `$wpdb->prepare()` for every query with variables; use `$wpdb->prefix`; avoid raw `LIKE` without `esc_like`.
- Files: validate uploads (`wp_check_filetype_and_ext`), never `include` user-controlled paths, avoid `eval`/`unserialize` on input; keep `index.php` silence files and `defined('ABSPATH') || exit;` guards.
- Secrets in `wp-config.php`/environment, never in the theme/plugin or repository. White-label/CRM tools hold customer data: minimise it, protect exports, support erasure/export hooks where relevant (privacy tools).

## Structure and quality
- Prefix everything (functions, classes, options, hooks, handles); namespace or class-based modules; load assets with `wp_enqueue_*` and version strings, only on pages that need them.
- Activation/deactivation/`uninstall.php` must clean up only what the plugin created; upgrades use a stored DB version and migration routine.
- i18n: `__()`/`_e()` with a text domain, `languages/` kept in sync.
- Lint: `php -l` on changed files, `phpcs --standard=WordPress` if configured, PHPStan/Psalm if present, PHPUnit/WP test suite if present. Test with `WP_DEBUG` and `WP_DEBUG_LOG` on.

## Performance
Measure with Query Monitor and server timings. Typical wins: avoid queries in loops (prime caches, `WP_Query` with `no_found_rows`, `fields => 'ids'`), cache expensive work with transients/object cache and a clear invalidation, autoload only small options (`autoload = no` for large ones), conditional asset loading, image sizes and lazy loading, avoid remote HTTP on page load, cron (`wp_schedule_event`) for heavy jobs, nginx FastCGI/page cache with correct bypass for logged-in users.

## Hosting
nginx + PHP-FPM: `try_files`, deny access to dotfiles, `xmlrpc.php` and uploads PHP execution; correct `fastcgi_pass`, upload size limits matching PHP `upload_max_filesize`/`post_max_size`; behind Cloudflare use trusted real-IP ranges only. Use the `linux-server-admin` skill for host changes and never edit a live site's files or database without approval; use WP-CLI on a staging copy first (`wp search-replace --dry-run`).

## Releases
Bump the version in the plugin header/`style.css`, constant, `readme.txt`/changelog and any update manifest together; zip without dev files; record checksums; follow the repo's upload instructions.
