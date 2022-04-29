#	"bats" tests for generate_archive and extract_archive
#
#       see: https://github.com/bats-core/bats-core
#       see: https://hub.docker.com/r/bats/bats
#
#       N.B. The script assumes that the bats intepreter is invoked from the
#            root directory of the archive project
#
#       examples:
#               run all .bats scripts in "test":
#                       cd $ARCHIVE_HOME ; bats test
#
#               run all .bats scripts in "test" using docker:
#                       docker run --rm -v "$(pwd):/mnt" -w /mnt bats/bats:latest test

setup() {
    pushd bin
    d=$(pwd)
    export PATH="$d:$PATH"
    popd

    cd test

    /bin/rm -rf testdir
    mkdir testdir
    cp -r testsrc/* testdir

    export ARCHIVE_TEST_GPG='--batch --pinentry-mode loopback --passphrase-file passphrase'

    cd testdir
}

@test "check environment" {
    [ -d dir1 -a -d dir2 -a -f file1 -a -d 'white space' -a -f passphrase ]
}

@test "generate from tar, discard results" {
    generate_archive -o /dev/null dir1 dir2
}

@test "generate from tar, check results" {
    generate_archive -o gen.out.tgz dir1 dir2
    extract_archive -a gen.out.tgz -c
}

@test "generate from tar to stdout, check results" {
    generate_archive -o - dir1 dir2 > gen.stdout.tgz
    extract_archive -a gen.stdout.tgz -c
}

@test "generate from stdin, check results from stdin" {
    tar cf out.tar dir1 file1
    generate_archive -a - -o - < out.tar > gen.stdout.tgz
    extract_archive -a - -c < gen.stdout.tgz
}

@test "check alternate manifest names" {
    tar cf out.tar dir1 file1
    generate_archive -a - -m 'my manifest' -o - < out.tar > gen.stdout.tgz
    extract_archive -a - -m 'my manifest' -c < gen.stdout.tgz
}

@test "read from tar archive, don't check results" {
    tar cf out.tar dir1 file1
    generate_archive -a out.tar -o - > gen.stdout.tgz
    extract_archive -a - -C -o - < gen.stdout.tgz > ext.out
    tar tf ext.out
}

@test "generate from tar, extract all, don't check results but provide bogus manifest" {
    generate_archive -o gen.out.tgz dir1 dir2
    mkdir extract
    cd extract
    ln ../passphrase
    extract_archive -C -a ../gen.out.tgz
    [ -d "dir1" -a -d "dir2" ]
}

@test "generate from tar, extract only dir2, check results" {
    generate_archive -o gen.out.tgz dir1 dir2
    mkdir extract
    cd extract
    ln ../passphrase
    extract_archive -a ../gen.out.tgz -m ../manifest dir2
    [ -d "dir2" -a ! -e "dir1" ]
}

@test "generate from tar, extract all named targets, diff results" {
    generate_archive -o gen.out.tgz dir1 dir2
    mkdir extract
    cd extract
    ln ../passphrase
    extract_archive -a ../gen.out.tgz -m ../manifest dir2 dir1
    diff -r dir1 ../dir1
    diff -r dir2 ../dir2
}

@test "generate from tar with white space in args, extract named targets, diff results" {
    generate_archive -o gen.out.tgz 'white space' file2 'black space' dir2
    mkdir extract
    cd extract
    ln ../passphrase
    extract_archive -a ../gen.out.tgz -m ../manifest 'black space' dir2 'white space'
    diff -r dir2 ../dir2
    diff -r 'black space' '../black space'
    diff -r 'white space' '../white space'
}

@test "fail on no output specified" {
    run generate_archive dir1 dir2 > gen.stdout.tgz
    [ "${status}" -ne 0 ]
}

@test "fail on missing input, generate" {
    run generate_archive -a blah dir1 dir2 -o gen.stdout.tgz
    [ "${status}" -ne 0 ]
}

@test "fail on missing input, extract" {
    run extract_archive -a blah
    [ "${status}" -ne 0 ]
}

@test "fail on missing manifest, extract" {
    run extract_archive -a - -m bogus < /dev/null
    [ "${status}" -ne 0 ]
}

@test "fail on check and no-check" {
    run extract_archive -a - -c -C < /dev/null
    [ "${status}" -ne 0 ]
}

@test "fail on check with output" {
    run extract_archive -a - -c -o - < /dev/null > /dev/null
    [ "${status}" -ne 0 ]
}

@test "fail on generate from stdin and tar" {
    tar cf out.tar dir1 file1
    run generate_archive -a - -o - dir1 dir2 < out.tar > gen.stdout.tgz
    [ "${status}" -ne 0 ]
}

@test "fail when sha is wrong" {
    generate_archive -o - dir1 dir2 > gen.stdout.tgz
    sed -f sedfile-sha manifest > manifest.bad
    run extract_archive -m manifest.bad -a gen.stdout.tgz -c
    [ "${status}" -ne 0 ]
}

@test "fail when size is wrong, extract" {
    generate_archive -o gen.out.tgz dir1 dir2
    mkdir extract
    cd extract
    ln ../passphrase
    sed -f ../sedfile-size ../manifest > manifest.bad
    run extract_archive -m manifest.bad -a ../gen.out.tgz
    [ "${status}" -ne 0 ]
}
