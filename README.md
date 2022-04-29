# Generate/Extract Archives suitable for long-term storage

The use case is preparing/recovering archives for/from long-term (disaster recovery) storage.
We want to check integrity after the archive has been moved around and kept who-knows-where
for a period of time.

See the comments in the code (found in `bin`) for more information.
Summary info can be obtained by invoking the scripts with the "-h" (help) option.

## generate_archive

Builds an encrypted `tar` archive along with a manifest.
An existing `tar` archive can be used as the input.

## extract_archive

Decrypts an archive and extracts the contents.  Named targets can be extracted instead of extracting everything.
The archive is checked against the manifest for correct size and sha256 sum.
The archive is checked along with decryption and/or extraction.
Checking can be disabled (-C) if, for example, the manifest is not available.

## code and dependencies

The scripts are written in `bash`.

- [argbash](https://argbash.io) is used to generate argument processing code.
- Common Unix utilities are needed: tar, sed, shasum, m4 (for `argbash`), ls, du, wc, ..
- GNU gpg is used for symmetric encryption/decryption.
- [bats](https://github.com/bats-core/bats-core) is used for testing.

You can copy these scripts and rename them as you like. You most likely will
want them findable using your `PATH` environment variable.

*A note about tar*: there are a few versions of `tar` floating around and they can be incompatible.
It would be best if the same version was used for generation and extraction.  The Darwin version
has been tested here.  The GNU version compiled but with errors during `make check` on MacOS, so
who knows.

*Another note about tar*: at present, there is no way to pass options to `tar` using these scripts.
`tar` is invoked without any special options.  This means, among other things, that hard links
are preserved and soft (symbolic) links are not followed.  This needs to be considered when extracting
(unpacking) the archives: absolute soft links may break, hard links from outside the directory
hierarchy are not going to be re-established. But this is disaster recovery, not backup/restore. In
a disaster, you may likely be just trying to get files back in some completely different environment.

In short, these scripts are meant to automate repeating tasks; tasks that are **well understood** by
the user: a user that understands how things work.  They are not meant for non-sophisticated users.

## testing

Testing has been, so far, done on Darwin (MacOS Monterey).

A test suite written in `bats` is in the `tests` directory.

## examples

- generate an archive from two directories: `generate_archive -o arch.tgz.gpg dir1 dir2`
- generate an archive from an existing tarfile: `generate_archive -a arch.tar -o arch.tar.gpg`
- extract everything from an archive: `extract_archive -a arch.tgz.gpg`
- extract a single directory from an archive: `extract_archive -a arch.tgz.gpg dir2`
- extract a single directory from an archive: `extract_archive -a arch.tgz.gpg dir2`
- recover the tarfile without extracting: `extract_archive -a arch.tgz.gpg -o arch.tgz`
- check an archive for integrity: `extract_archive -a arch.tgz.gpg -c`
- run the tests (from top directory): `bats test`

Last update at version `0.3.0`
