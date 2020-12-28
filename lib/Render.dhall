let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Render =
      { Type = { script : Text, file : Optional Text }
      , default = { script = "dhall/render", file = None Text }
      }

let renderFile =
      \(opts : Render.Type) ->
        merge
          { Some = \(file : Text) -> file, None = "dhall/files.dhall" }
          opts.file

let render =
      \(opts : Render.Type) ->
          [     opts.script
            ++  merge
                  { Some = \(file : Text) -> " " ++ file, None = "" }
                  opts.file
          ]
        : Bash.Type

in  Render /\ { render, renderFile }
