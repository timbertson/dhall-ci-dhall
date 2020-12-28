let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Bump =
      { Type = { script : Text, specs : List Text, freezeCmd : Optional Text }
      , default =
        { script = "dhall/bump", specs = [] : List Text, freezeCmd = None Text }
      }

let bump =
      \(opts : Bump.Type) ->
      \(files : List Text) ->
        let specArgs =
              Prelude.List.map
                Text
                Text
                (\(spec : Text) -> "--to ${Bash.doubleQuote spec}")
                opts.specs

        let freezeArg =
              merge
                { None = [] : List Text
                , Some =
                    \(cmd : Text) -> [ "--freeze-cmd=${Bash.doubleQuote cmd}" ]
                }
                opts.freezeCmd

        let cmd =
              Prelude.Text.concatSep
                " "
                ( Prelude.List.concat
                    Text
                    [ [ opts.script ], specArgs, freezeArg, files ]
                )

        in  [ cmd ] : Bash.Type

in  Bump /\ { bump }
