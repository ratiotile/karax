## Simple tool to quickly run Karax applications. Generates the HTML
## required to run a Karax app and opens it in a browser.

import os, 
  strutils, 
  parseopt, 
  browsers, 
  times, 
  tables
  


const
  css = """
  <link rel="stylesheet" href="../src/style.css">
"""
  html = """
<!DOCTYPE html>
<html>
<head>
  <title>$1</title>
  $2
</head>
<body id="body">
<div id="ROOT">
  $3
</div>
<script type="text/javascript" src="$1.js"></script>
</body>
</html>
"""

proc exec(cmd: string) =
  if os.execShellCmd(cmd) != 0:
    quit "External command failed: " & cmd

proc build(name: string, rest: string, selectedCss: string, run: bool) =
  echo("Building...")
  createDir("nimcache")
  exec("nim js --out:nimcache/" & name & ".js " & rest)
  let dest = "nimcache" / name & ".html"
  writeFile(dest, html % [name, selectedCss, ""])
  if run: openDefaultBrowser(dest)

proc buildStatic(name: string, rest: string, selectedCss: string, run: bool) =
  echo("Build static page...")
  # first compile site as executable
  createDir("nimcache")
  exec("nim c --out:nimcache/" & name & ".exe " & rest)
  exec("nimcache\\" & name & ".exe")
  exec("nim js --out:nimcache/" & name & ".js " & rest)
  if run: openDefaultBrowser("http://localhost:8000/" / name & ".html") # need to ensure this matches staticsite

proc main =
  var op = initOptParser()
  var rest = op.cmdLineRest
  var file = ""
  var run = false
  var genStatic = false
  var selectedCss = ""
  var watch = false
  var files: Table[string, Time] = {"path": getLastModificationTime(".")}.toTable

  while true:
    op.next()
    case op.kind
    of cmdLongOption:
      case op.key
      of "run":
        run = true
        rest = rest.replace("--run ")
      of "css":
        selectedCss = css
        rest = rest.replace("--css ")
      of "static":
        genStatic = true
        rest = rest.replace("--static ")
      else: discard
    of cmdShortOption:
      if op.key == "r":
        run = true
        rest = rest.replace("-r ")
      if op.key == "w":
        watch = true
        rest = rest.replace("-w ")
    of cmdArgument: file = op.key
    of cmdEnd: break

  if file.len == 0: quit "filename expected"
  let name = file.splitFile.name
  if genStatic:
    buildStatic(name, rest, selectedCss, run)
  else:
    build(name, rest, selectedCss, run)
  echo("after build")
  if watch:
    # TODO: launch http server
    while true:
      sleep(300)
      for path in walkDirRec("."):
        if ".git" in path:
          continue
        if files.hasKey(path):
          if files[path] != getLastModificationTime(path):
            echo("File changed: " & path)
            build(name, rest, selectedCss, run)
            files[path] = getLastModificationTime(path)
        else:
          files[path] = getLastModificationTime(path)

main()




