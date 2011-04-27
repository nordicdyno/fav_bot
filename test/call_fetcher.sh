#!/bin/sh
perl -Ilib bin/fetch_favicons.pl --url-source=test/uris.txt \
    --store-dir=test/orig \
    --out-dir=test/rslt

