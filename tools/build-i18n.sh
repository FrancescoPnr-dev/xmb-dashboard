#!/bin/sh
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Regenerates the translation template and compiles the shipped catalogs.
set -e
cd "$(dirname "$0")/.."

DOMAIN=plasma_applet_org.kde.plasma.xmbdashboard

find contents -name "*.qml" | sort | xargs xgettext --from-code=UTF-8 -C \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    --package-name="$DOMAIN" -o "po/$DOMAIN.pot"

for po in po/*.po; do
    lang=$(basename "$po" .po)
    msgmerge --update --backup=none "$po" "po/$DOMAIN.pot"
    mkdir -p "contents/locale/$lang/LC_MESSAGES"
    msgfmt "$po" -o "contents/locale/$lang/LC_MESSAGES/$DOMAIN.mo"
done
