# Getting Spidermonkey

This is how I get the spidermonkey (`js_src`) code.

The main idea is to check out the correct Mercurial tag and then just import those files into Git. I am not a Mozilla developer, so that is easier said than done.

The objective (suggested by Mikeal in this project's infancy) is to pull spidermonkey right out of stable Firefox releases, not from the tracemonkey repository, or anything else ostensibly more official or more convenient. That way we can tell users, "Test your code in Firefox or Firebug. If it works there, it works in CouchDB."

## Procedure

1. `hg clone --verbose http://hg.mozilla.org/releases/mozilla-release`
1. `hg checkout FIREFOX_6_0_RELEASE`
1. `tar cf /tmp/js.tar mfbt js/src`
1. Move to build-couchdb/dependencies/spidermonkey
1. `rm -r *`
1. `tar xf /tmp/js_src.tar && rm /tmp/js_src.tar`
1. `git add .`
1. `git diff --cached` # See how things look

## Notes

You can browse the mercurial repositories at http://hg.mozilla.org/

The old repository for the original `js_src` code:

* URL: http://hg.mozilla.org/releases/mozilla-2.1
* Tag: `FIREFOX_3_7a3_RELEASE`
