let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Bump =
      { Type =
          { script : Text
          , specs : List Text
          , freezeCmd : Optional Text
          , allowUnused : Bool
          , ifAffects : List Text
          }
      , default =
        { script = "dhall/bump"
        , specs = [] : List Text
        , ifAffects = [] : List Text
        , freezeCmd = None Text
        , allowUnused = False
        }
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

        let ifAffectsArgs =
              Prelude.List.map
                Text
                Text
                (\(path : Text) -> "--if-affects ${Bash.doubleQuote path}")
                opts.ifAffects

        let freezeArg =
              merge
                { None = [] : List Text
                , Some =
                    \(cmd : Text) -> [ "--freeze-cmd=${Bash.doubleQuote cmd}" ]
                }
                opts.freezeCmd

        let allowUnusedArg =
              if opts.allowUnused then [ "--allow-unused" ] else [] : List Text

        let cmd =
              Prelude.Text.concatSep
                " "
                ( Prelude.List.concat
                    Text
                    [ [ opts.script ]
                    , specArgs
                    , ifAffectsArgs
                    , freezeArg
                    , allowUnusedArg
                    , files
                    ]
                )

        in  [ cmd ] : Bash.Type

in  Bump /\ { bump }
