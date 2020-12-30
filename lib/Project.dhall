let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Make = CI.Make

let Bash = CI.Bash

let Base = ./Base.dhall

let Render = ./Render.dhall

let Bump = ./Bump.dhall

let Project =
      { mode : Base.Mode
      , packages : List Text
      , format : Base.Format.Type
      , lint : Base.Lint.Type
      , render : Optional Render.Type
      , freeze : Optional Base.Freeze.Type
      , bump : Optional Bump.Semantic.Type
      , docs : Optional Base.Docs.Type
      }

let default =
      { mode = Base.Mode.ASCII
      , format = Base.Format.default
      , lint = Base.Lint.default
      , render = Some Render.default
      , freeze = Some Base.Freeze.default
      , bump = None Bump.Semantic.Type
      , docs = None Base.Docs.Type
      }

let _testDefault =
        assert
      :     (default // { packages = [ "package.dhall" ] } : Project).packages
        ===  [ "package.dhall" ]

let Makefile =
    -- reserved for future extensibility
      { Type = {}, default = {=} }

let runOnAll =
      \(action : Text -> Bash.Type) ->
      \(files : List Text) ->
        Prelude.List.concat Text (Prelude.List.map Text Bash.Type action files)

let makefileTargets =
      \(project : Project) ->
      \(make : Makefile.Type) ->
        let optional =
              \(T : Type) ->
              \(opt : Optional T) ->
              \(fn : T -> List Make.Target.Type) ->
                merge
                  { None = [] : List Make.Target.Type, Some = \(t : T) -> fn t }
                  opt

        in      [ Make.Target.Phony::{
                  , name = "eval"
                  , script =
                      runOnAll (Base.evaluate project.mode) project.packages
                  }
                , Make.Target.Phony::{
                  , name = "format"
                  , script =
                      runOnAll
                        (Base.evaluateAndFormat project.mode project.format)
                        project.packages
                  }
                , Make.Target.Phony::{
                  , name = "format-only"
                  , script =
                      runOnAll
                        (Base.format project.mode project.format)
                        project.packages
                  }
                , Make.Target.Phony::{
                  , name = "lint"
                  , script =
                      runOnAll
                        (Base.evaluateAndLint project.mode project.lint)
                        project.packages
                  }
                ]
              # optional
                  Base.Freeze.Type
                  project.freeze
                  ( \(freeze : Base.Freeze.Type) ->
                      [ Make.Target.Phony::{
                        , name = "freeze"
                        , script =
                            runOnAll
                              (Base.evaluateAndLint project.mode project.lint)
                              project.packages
                        }
                      ]
                  )
              # optional
                  Render.Type
                  project.render
                  ( \(render : Render.Type) ->
                      [ Make.Target.Phony::{
                        , name = "render"
                        , script = Render.render render
                        }
                      ]
                  )
              # optional
                  Bump.Semantic.Type
                  project.bump
                  ( \(bump : Bump.Semantic.Type) ->
                      [ Make.Target.Phony::{
                        , name = "bump"
                        , script = Bump.semantic bump
                        }
                      ]
                  )
              # optional
                  Base.Docs.Type
                  project.docs
                  ( \(docs : Base.Docs.Type) ->
                      [ Make.Target.Phony::{
                        , name = "docs"
                        , script = Base.docs project.mode docs
                        }
                      ]
                  )
            : List Make.Target.Type

let makefile =
      \(project : Project) ->
      \(make : Makefile.Type) ->
        Make.render Make::{ targets = makefileTargets project make } : Text

in  { Type = Project, default, Makefile, makefileTargets, makefile }
