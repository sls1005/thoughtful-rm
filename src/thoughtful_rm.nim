import std/[os, osproc, compilesettings, strutils]

const
  version = "thoughtful-rm 0.2.0"
  usage = """
usage: thoughtful_rm [options] <files>

options:

  --trm-help                      Show this help message and exit.

  --trm-version                   Show version information and exit.

  --no-external-cmd-invocation    Use this program not as a invoker of `rm`, but as a file-deleter. It removes directories recursively. This option is NOT recommended. (Warning: It can be less safe than `rm`.)

Normally, this program invokes the "rm" binary. Any flag not listed above is passed to "rm", along with other valid arguments.
For the usage of `rm`, see `--help`.
"""

proc printUsage {.raises: [], inline.} =
  echo version, "\n\n", usage

proc printVersion {.raises: [], inline.} =
  const details = """
Compiled with the "$1" backend & "--mm:$2."
""".format(
    compilesettings.querySetting(SingleValueSetting.backend),
    compilesettings.querySetting(SingleValueSetting.gc)
  )
  echo version, "\n\n", details

proc printErrMsg(msg: string) {.raises: [IOError, ValueError], inline.} =
  stderr.write("\x1b[1;31m[Error]\x1b[0m $1\n" % msg)

proc protectEverything {.raises: [IOError], inline.} =
  stderr.write("\x1b[1;31m[!]\x1b[0m It seems that you were trying to delete every file on the system, recursively.\n")
  quit(-1)

proc ask(question: string): string {.raises: [IOError], inline.} =
  stdout.write(question)
  return stdin.readLine()

{.push boundChecks: off.}
proc hasAllFilesFrom(self: seq[string]; dir: string, useRelativePath = true): uint8 {.raises: [OSError].} =
  # 0 if doesn't have (or if the dir is empty), 1 if it does but there's only 1 file in the dir, 2 if it does and the dir contains more than 1 files.
  # This does not count files whose names start with "."
  var n: uint8 = 0
  for file in walkDir(dir, relative=useRelativePath):
    let filename = file.path.lastPathPart()
    if likely(filename.len > 0):
      if unlikely(filename[0] == '.'): # < (unnecessary) bound check [disabled] >
        # file invisible
        continue
    if not(file.path in self):
      return 0
    elif unlikely(n < 2):
      inc(n)
  return n
{.pop.}

proc fileOrDirOrSymlinkExists(path: string): bool {.raises: [], inline.} =
  fileExists(path) or dirExists(path) or symlinkExists(path)

proc isCurrentDir(path: string): bool {.raises: [ValueError, OSError], inline.} =
  os.absolutePath(path) == os.getCurrentDir()

{.push boundChecks: off.}
proc isRootDir(path: string): bool {.raises: [], inline.} =
  if len(path) == 1:
    return (path[0] == '/') # < (unnecessary) bound check [disabled] >
  else:
    false
{.pop.}

{.push boundChecks: off, rangeChecks: off, overflowChecks: off.}
proc main(): int =
  let
    n = os.paramCount() # n >= 0 | < range check [disabled] >
  var
    files = newSeqOfCap[string](n)
    noExternalCmdInvocation = false
    opts, dirs: seq[string]
  result = 0
  if n == 0:
    printUsage()
    return
  # 0 < n <= int.high
  for k in 1 .. n:
    let param = os.paramStr(k)
    if unlikely(param == ""):
      continue
    elif unlikely(param[0] == '-'): # < (unnecessary) bound check [disabled] >
      case param:
      of "--trm-help":
        printUsage()
        return
      of "--trm-version":
        printVersion()
        return
      of "--no-external-cmd-invocation":
         noExternalCmdInvocation = true
      else:
        opts.add(param) # param sinks
    elif likely fileOrDirOrSymlinkExists(param):
      files.add(param) # param sinks
    else:
      printErrMsg(param & " not found. Nothing deleted.")
      return 2
    # < (unnecessary) overflow check [disabled] >
  {.push assertions: off.}
  for file in files: # len(files) <= n | < (unnecessary) bound check [disabled] >
    let dir = os.parentDir(file)
    if likely(dir in dirs):
      continue
    elif unlikely(file.isRootDir()):
      if noExternalCmdInvocation:
        protectEverything()
      else:
        let ans = ask(
          "\x1b[1;33m[!]\x1b[0m Do you really want to remove the root directory (\"/\") ? (Say yes or no. Warning: You will lose everything!) "
        )
        if ans != "yes":
          echo "Nothing deleted. Quitting..."
          return
    else:
      let
        isCurrent = dir.isCurrentDir()
        dirIsRoot = dir.isRootDir()
      if files.hasAllFilesFrom(dir, useRelativePath=isCurrent) > 1:
        # "rm dir/*"
        if noExternalCmdInvocation and dirIsRoot:
          protectEverything()
        else:
          let
            folder = (
              if isCurrent:
              "the current directory (\"$1\")" % os.getCurrentDir()
              elif dirIsRoot:
                "the root directory (\"/\")"
              else:
                "\"$1/\"" % dir
            )
            ans = ask(
              "\x1b[1;35m[?]\x1b[0m Do you wish to delete all files and subdirectories from $1 ? [y/N] " % folder
            )
          if ans notin ["y", "yes"]:
            echo "Nothing deleted. Quitting..."
            return
      dirs.add(dir) # dir sinks
      # < (unnecessary) overflow check [disabled] | (automatically inserted) assertion [disabled] >
  try:
    if noExternalCmdInvocation:
      for path in files: # < (unnecessary) bound check [disabled] >
        if os.getFileInfo(path).kind == pcDir:
          os.removeDir(path)
        else:
          os.removeFile(path)
        # < (unnecessary) overflow check [disabled] | (automatically inserted) assertion [disabled] >
    else:
      let res = osproc.startProcess(
        "rm",
        args = opts & files,
        options = {poUsePath, poParentStreams}
      ).waitForExit()
      return res
  except OSError as e:
    printErrMsg(e.msg)
    return e.errorCode
  {.pop.}
{.pop.}


when isMainModule:
  let res = main()
  quit(res)
