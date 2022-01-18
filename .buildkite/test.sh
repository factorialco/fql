bundle exec rspec
ret=$?
ls -lah
rm -fr coverage
exit $ret
