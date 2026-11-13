"""Exercise scan status, localized output, report capture, and cleanup safely."""

import pathlib,tempfile,subprocess,os
src=(pathlib.Path(__file__).resolve().parents[1] / 'core/tabs/security/rkhunter-scan.sh').read_text().split('checkEnv\ninstallRkhunter')[0].replace('. ../common-script.sh','')
for case,status,summary,expected in [('clean',0,True,0),('localized',0,True,0),('warnings',1,True,0),('config',1,False,1),('fatal',2,True,1),('tee',0,True,1),('copy',0,True,1),('allocation',0,True,1)]:
 with tempfile.TemporaryDirectory() as d:
  p=pathlib.Path(d);(p/'home').mkdir();(p/'bin').mkdir()
  mock='''#!/bin/sh
case "$1" in
mktemp) [ "$CASE" = allocation ] && exit 1; shift; exec mktemp -d "$TEST_ROOT/root-XXXXXXXX";;
rm) shift; exec rm "$@";;
cat) [ "$CASE" = copy ] && exit 1; shift; exec cat "$@";;
rkhunter) shift; [ "$1" = --update ] && exit 1
language=de
while [ "$1" != --logfile ]; do
 [ "$1" = --language ] && language="$2"
 shift
done
printf 'detailed private log\\n' > "$2"
if [ "$SUMMARY" = True ]; then
 if [ "$language" = en ]; then
  printf 'System checks summary\\n'
 else
  printf 'Zusammenfassung der Systempruefungen\\n'
 fi
fi
exit "$SCAN_EXIT";;
esac
exit 99
'''
  (p/'bin/escalate').write_text(mock);(p/'bin/escalate').chmod(0o755)
  if case=='tee':
   (p/'bin/tee').write_text('#!/bin/sh\ncat > "$1"\nexit 1\n');(p/'bin/tee').chmod(0o755)
  env=dict(os.environ,HOME=str(p/'home'),TMPDIR=d,TEST_ROOT=d,CASE=case,SUMMARY=str(summary),SCAN_EXIT=str(status),PATH=str(p/'bin')+':'+os.environ['PATH'])
  r=subprocess.run(['sh','-e'],input=src+'\nESCALATION_TOOL=escalate\nrunScan\n',text=True,capture_output=True,env=env)
  reports=list((p/'home').iterdir()); leftovers=[x.name for x in p.iterdir() if x.name not in ('home','bin')]
  assert r.returncode==expected,(case,r.returncode,r.stderr)
  assert not leftovers,(case,leftovers)
  assert len(reports)==(expected==0),(case,reports)
  if reports: assert reports[0].read_text()=='detailed private log\n'
  print(case,'PASS',r.returncode,'cleanup PASS')
