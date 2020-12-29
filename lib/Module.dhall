{-
  I wish dhall would drop unicode support, but I don't want to turn people away for valid choices so I'll support it here.

  So that we don't have to pass Mode into Every Single Function, we parmaterise the whole module over it
  and you just reference the version you want. ASCII is still the default though because I have strong opinions ;)
-}
let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Workflow = CI.Workflow

let Git = CI.Git

let Step = Workflow.Step

let Base = ./Base.dhall

let Render = ./Render.dhall

let Bump = ./Bump.dhall

let make =
      \(mode : Base.Mode) ->
        let evaluate = Base.evaluate mode

        let format = Base.format mode

        let lint = Base.lint mode

        let evaluateAndLint = Base.evaluateAndLint mode

        let evaluateAndFormat = Base.evaluateAndFormat mode

        let freeze = Base.freeze mode

        in      Render.{ render }
            /\  Bump.{ bump }
            /\  { evaluate
                , evaluateAndFormat
                , evaluateAndLint
                , Format = Base.Format
                , format
                , Lint = Base.Lint
                , lint
                , Freeze = Base.Freeze
                , freeze
                , Render = Render.{ Type, default }
                , Bump = Bump.{ Type, default, Semantic, semantic }
                , Workflow =
                  { cache =
                      \(globs : List Text) ->
                        let globStrings =
                              Prelude.List.map
                                Text
                                Text
                                (\(g : Text) -> "'${g}'")
                                globs

                        let globArguments =
                              Prelude.Text.concatSep ", " globStrings

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
                                (lint Base.Lint::{ transitive = True } file)
                          )
                  , enforceRender =
                      \(opts : Render.Type) ->
                        Git.requireCleanWorkspaceAfterRunning
                          (   Render.render opts
                            # lint
                                Base.Lint::{ transitive = True }
                                (Render.renderFile opts)
                          )
                  }
                }

in  { Mode = Base.Mode, make }
