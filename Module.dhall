{-
  I wish dhall would drop unicode support, but I don't want to turn people away for valid choices so I'll support it here.

  So that we don't have to pass Mode into Every Single Function, we parmaterise the whole module over it
  and you just reference the version you want. ASCII is still the default though because I have strong opinions ;)
-}
let Prelude = ./dependencies/Prelude.dhall

let CI = ./dependencies/CI.dhall

let Bash = CI.Bash

let Workflow = CI.Workflow

let Git = CI.Git

let Step = Workflow.Step

let Mode = < Unicode | ASCII >

let ModifyOptions =
    -- common options for format, lint and freeze
      { transitive : Bool, check : Bool, file : Text }

let modifyDefault = { transitive = True, check = False }

let Format = { Type = ModifyOptions, default = modifyDefault }

let Lint = { Type = ModifyOptions, default = modifyDefault }

let Freeze =
      { Type = ModifyOptions //\\ { all : Bool, cache : Bool }
      , default = modifyDefault /\ { cache = False, all = False }
      }

let make =
      \(mode : Mode) ->
        let dhall =
              merge
                { Unicode = "dhall --unicode", ASCII = "dhall --ascii" }
                mode

        let cmd =
              \(args : List Text) ->
              \(file : Text) ->
                  [ "${dhall} ${Prelude.Text.concatSep " " args} \"${file}\"" ]
                : Bash.Type

        let evaluate =
              \(file : Text) ->
                  [ "${dhall} --plain --file \"${file}\" > /dev/null" ]
                : Bash.Type

        let optional =
              \(flag : Text) ->
              \(enable : Bool) ->
                if enable then [ flag ] else [] : List Text

        let modifyFlags =
            -- NOTE: trasitive / inplace must be the last argument
              \(opts : ModifyOptions) ->
                  optional "--check" opts.check
                # ( if    opts.transitive
                    then  [ "--transitive" ]
                    else  [ "--inplace" ]
                  )

        let freezeFlags =
              \(opts : Freeze.Type) ->
                  optional "--all" opts.all
                # optional "--cache" opts.cache
                # modifyFlags opts.{ transitive, check, file }

        let format =
              \(opts : Format.Type) ->
                cmd ([ "format" ] # modifyFlags opts) opts.file

        let lint =
              \(opts : Lint.Type) ->
                cmd ([ "lint" ] # modifyFlags opts) opts.file

        let evaluateAndLint =
              \(opts : Lint.Type) -> evaluate opts.file # lint opts

        let freeze =
              \(opts : Freeze.Type) ->
                cmd ([ "freeze" ] # freezeFlags opts) opts.file

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

        in  { evaluate
            , Format
            , format
            , Lint
            , lint
            , evaluateAndLint
            , Freeze
            , freeze
            , Render
            , render
              -- TODO bump
            , Workflow =
              { cache =
                  \(globs : List Text) ->
                    let globStrings =
                          Prelude.List.map
                            Text
                            Text
                            (\(g : Text) -> "'${g}'")
                            globs

                    let globArguments = Prelude.Text.concatSep ", " globStrings

                    in  Workflow.Step::{
                        , name = Some "Dhall cache"
                        , uses = Some "actions/cache@v1"
                        , `with` = Some
                            ( toMap
                                { path = "~/.cache/dhall"
                                , key =
                                    "dhall-cache-\${{ hashFiles(${globArguments}) }}"
                                }
                            )
                        }
              , enforceLint =
                  \(file : Text) ->
                    Step.bash
                      (   evaluate file
                        # Git.requireCleanWorkspaceAfterRunning
                            (lint Lint::{ transitive = True, file })
                      )
              , enforceRender =
                  \(opts : Render.Type) ->
                    Git.requireCleanWorkspaceAfterRunning
                      (   lint
                            Lint::{ transitive = True, file = renderFile opts }
                        # render opts
                      )
              }
            }

in  { Mode, make }
