#!/bin/bash

repopath=/wwwroot/repo

for d in *; do
    if [ -d "$d" ]; then
        cd "$d"

        if makepkg -ms --noconfirm; then
            unset pkgname
            unset pkgver
            unset pkgrel
            unset latestpkg

            . ./PKGBUILD

            for pn in ${pkgname[@]}; do
                unset latestpkgver
                unset latestpkgrel
                unset latestpkgfullver

                for pkgfile in $(find . -maxdepth 1 -type f -regex "\./$pn-[0-9].+-[0-9]+-\(x86_64\|any\)\.pkg\.tar\.zst"); do
                    pkgfile=${pkgfile:2}
                    currentpkgver=$(echo $pkgfile | sed -E "s/$pn-([0-9].+)-([0-9]+)-(x86_64|any)\.pkg\.tar\.zst/\1/")

                    if [[ -z "$latestpkgver" ]] || [[ "$currentpkgver" > "$latestpkgver" ]] || [[ "$currentpkgver" = "$latestpkgver" ]]; then
                        latestpkgver=$currentpkgver
                        unset latestpkgrel
                        currentpkgrel=$(echo $pkgfile | sed -E "s/$pn-([0-9].+)-([0-9]+)-(x86_64|any)\.pkg\.tar\.zst/\2/")

                        if [[ -z "$latestpkgrel" ]] || [[ "$currentpkgrel" -gt "$latestpkgrel" ]]; then
                            latestpkgrel=$currentpkgrel
                        fi
                    fi
                done

                latestpkgfullver=$latestpkgver-$latestpkgrel

                for pkgfile in $(find . -maxdepth 1 -type f -regex "\./$pn-[0-9].+-[0-9]+-\(x86_64\|any\)\.pkg\.tar\.zst"); do
                    pkgfile=${pkgfile:2}
                    if [[ $latestpkgfullver > $(echo $pkgfile | sed -E "s/$pn-([0-9].+)-([0-9]+)-(x86_64|any)\.pkg\.tar\.zst/\1-\2/") ]]; then
                        rm -f "$pkgfile"
                        rm -f "$pkgfile.sig"
                        rm -f "$repopath/$pkgfile"
                        rm -f "$repopath/$pkgfile.sig"
                    else
                        cp "$pkgfile" $repopath/
                        cp "$pkgfile.sig" $repopath/
                        repo-add $repopath/bluehill.db.tar.zst $repopath/$pkgfile
                    fi
                done
            done
        fi

        cd ..
    fi
done
