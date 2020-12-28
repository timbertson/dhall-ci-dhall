let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Bump =
      { Type = { script : Text, specs : List Text }
      , default = { script = "dhall/bump", specs = [] : List Text }
      }

let bump =
      \(opts : Bump.Type) ->
      \(files : List Text) ->
        let specArgs =
              Prelude.List.map
                Text
                Text
                (\(spec : Text) -> "--to \"${spec}\"")
                opts.specs

        let cmd =
              Prelude.Text.concatSep
                " "
                (Prelude.List.concat Text [ [ opts.script ], specArgs, files ])

        in  [ cmd ] : Bash.Type

in  Bump /\ { bump }
