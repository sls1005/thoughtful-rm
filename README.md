# Thoughtful rm

A wrapper of the `rm` command, with additional checks.

### Background

> One night when I was coding on [Termux](https://github.com/termux/termux-app), I accidentally typed `rm -rf *`, then stopped it immediately with Ctrl-C. Thankfully, not all of my files were deleted, only few of them. Now I can see why everyone said that it wasn't safe to use.

### Ideas

+ When somebody use `rm -rf *` (or `rm *`), it is likely that he or she wasn't thinking clearly. It could also be a result of typo. (e.g. `rm * .c`)

+ When someone tries to remove many files, but not all files from a dir, it means he or she was very carefully not to remove all files, so it's not necessary to be confirmed.

+ When `rm` is invoked by a script, it is unlikely to be a mistake, so it's not necessary to be checked.

+ If any of the files mentioned in the arguments does not exist, the command should be considered invalid, and nothing should be deleted.

### Build & Install

#### Build from source

+ This requires the [Nim](https://github.com/nim-lang/Nim) compiler.

Once you have Nim installed, you can download and build with the following commands:
```sh
git clone https://github.com/sls1005/thoughtful-rm
cd thoughtful_rm/src
nim c thoughtful_rm.nim
```

It is recommended to set `rm` as an alias for this executable.
```sh
# ~/.profile
alias rm=/path/to/thoughtful_rm
```

### Note

+ Normally, this invokes the `rm` binary on the system. Please ensure that it's in your `PATH`.

+ Although it's possible to replace the functions of `rm` with that of this executable (via `--no-external-cmd-invocation`), doing so is not recommended.
