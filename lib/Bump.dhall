let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Bump =
      { Type =
          { script : Text
          , specs : List Text
          , freezeCmd : Optional Text
          , allowUnused : Bool
          }
      , default =
        { script = "dhall/bump"
        , specs = [] : List Text
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
                    , freezeArg
                    , allowUnusedArg
                    , files
                    ]
                )

        in  [ cmd ] : Bash.Type

let Semantic =
      { Type = { bump : Bump.Type, files : List Text, outputs : List Text }
      , default.bump = Bump.default
      }

let semantic =
    {-
    Like bump, but applies specs one at a time. At each stage,
    a backup of inputs is taken. If the semantic hash of all packages is
    unchanged after a bump, it is rolled back.

    This prevents making unnecessary bumps where either the dhall
    expression in the git repository is unchanged, or the changes
    don't affect the result of this package.

    Since a failed semantic bump may leave the repository in
    an inconsistent state, we require a clean workspace initially.
    -}

      \(opts : Semantic.Type) ->
        let eachFile =
              \(files : List Text) ->
              \(cmd : Text -> Text) ->
                Prelude.List.map Text Text cmd files

        let addHashTo =
              \(dest : Text) ->
              \(file : Text) ->
                "${dest}+=\"\$(dhall hash --file ${Bash.doubleQuote file})\""

        let applyBump =
              \(spec : Text) ->
                Bash.join
                  [ [ "echo"
                    , "echo \"Applying bump: ${spec}\""
                    , "originalHashes=''"
                    , "finalHashes=''"
                    ]
                  , eachFile opts.outputs (addHashTo "originalHashes")
                  , eachFile
                      opts.files
                      (\(file : Text) -> "cp ${Bash.doubleQuote file}{,.orig}")
                  , bump (opts.bump // { specs = [ spec ] }) opts.files
                  , eachFile opts.outputs (addHashTo "finalHashes")
                  , Bash.ifElse
                      "[ \"\$originalHashes\" = \"\$finalHashes\" ]"
                      (   eachFile
                            opts.files
                            ( \(file : Text) ->
                                "mv ${Bash.doubleQuote file}{.orig,}"
                            )
                        # [ "echo \"  [Reverting bump: ${spec}\"]" ]
                      )
                      (   eachFile
                            opts.files
                            ( \(file : Text) ->
                                "rm ${Bash.doubleQuote file}.orig"
                            )
                        # [ "echo \"Applied: ${spec}\"" ]
                      )
                  ]

        let bumpFn =
            -- To minimize noise in the generated makefile, we encode bump as a function and call it many times,
            -- rather than repeating the literal bash script for each spec
              Bash.join
                [ [ "function bump {" ]
                , Bash.indent (applyBump "\$1")
                , [ "}" ]
                ]

        let applyBumps =
              if    Prelude.List.null Text opts.bump.specs
              then  [ "echo 'ERROR: no explicit bump specs are provided'" ]
              else    bumpFn
                    # Prelude.List.map
                        Text
                        Text
                        (\(spec : Text) -> "bump ${Bash.doubleQuote spec}")
                        opts.bump.specs

        in  Bash.join
              [ [ "set +x" ]
              , Bash.`if`
                  "! git --no-pager diff --patch --exit-code --"
                  [ "echo >&2 'You have working changes, add or commit them first'"
                  , "exit 1"
                  ]
              , applyBumps
              ]

in  Bump /\ { bump, semantic, Semantic }
