#!/bin/bash
cd /Users/sgkrishna/MasterBase/Mediatron
bash quickbuild.sh
rm -rf /Applications/Mediatron.app ~/Applications/Mediatron.app dmg_staging Mediatron.dmg 2>/dev/null
cp -R Mediatron.app /Applications/
cp -R Mediatron.app ~/Applications/
mkdir dmg_staging
cp -R Mediatron.app dmg_staging/
ln -sf /Applications dmg_staging/Applications
hdiutil create -volname Mediatron -srcfolder dmg_staging -ov -format UDZO Mediatron.dmg 2>&1
rm -rf dmg_staging
killall Mediatron 2>/dev/null
open /Applications/Mediatron.app
md5 Mediatron.app/Contents/MacOS/Mediatron /Applications/Mediatron.app/Contents/MacOS/Mediatron ~/Applications/Mediatron.app/Contents/MacOS/Mediatron
du -sh Mediatron.app Mediatron.dmg
echo ALL SHIPPED