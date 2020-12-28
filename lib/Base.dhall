let Prelude = ../dependencies/Prelude.dhall

let CI = ../dependencies/CI.dhall

let Bash = CI.Bash

let Mode = < Unicode | ASCII >

let ModifyOptions =
    -- common options for format, lint and freeze
      { transitive : Bool, check : Bool }

let modifyDefault = { transitive = True, check = False }

let Format = { Type = ModifyOptions, default = modifyDefault }

let Lint = { Type = ModifyOptions, default = modifyDefault }

let Freeze =
      { Type = ModifyOptions //\\ { all : Bool, cache : Bool }
      , default = modifyDefault /\ { cache = False, all = False }
      }

let dhall =
      \(mode : Mode) ->
        merge { Unicode = "dhall --unicode", ASCII = "dhall --ascii" } mode

let cmd =
      \(mode : Mode) ->
      \(args : List Text) ->
      \(file : Text) ->
          [ "${dhall mode} ${Prelude.Text.concatSep " " args} \"${file}\"" ]
        : Bash.Type

let evaluate =
      \(mode : Mode) ->
      \(file : Text) ->
        [ "${dhall mode} --plain --file \"${file}\" > /dev/null" ] : Bash.Type

let optional =
      \(flag : Text) ->
      \(enable : Bool) ->
        if enable then [ flag ] else [] : List Text

let modifyFlags =
    -- NOTE: trasitive / inplace must be the last argument
      \(opts : ModifyOptions) ->
          optional "--check" opts.check
        # (if opts.transitive then [ "--transitive" ] else [ "--inplace" ])

let freezeFlags =
      \(opts : Freeze.Type) ->
          optional "--all" opts.all
        # optional "--cache" opts.cache
        # modifyFlags opts.{ transitive, check }

let format =
      \(mode : Mode) ->
      \(opts : Format.Type) ->
      \(file : Text) ->
        cmd mode ([ "format" ] # modifyFlags opts) file

let evaluateAndFormat =
      \(mode : Mode) ->
      \(opts : Format.Type) ->
      \(file : Text) ->
        evaluate mode file # format mode opts file

let lint =
      \(mode : Mode) ->
      \(opts : Lint.Type) ->
      \(file : Text) ->
        cmd mode ([ "lint" ] # modifyFlags opts) file

let evaluateAndLint =
      \(mode : Mode) ->
      \(opts : Lint.Type) ->
      \(file : Text) ->
        evaluate mode file # lint mode opts file

let freeze =
      \(mode : Mode) ->
      \(opts : Freeze.Type) ->
      \(file : Text) ->
        cmd mode ([ "freeze" ] # freezeFlags opts) file

in  { Mode
    , dhall
    , cmd
    , evaluate
    , evaluateAndLint
    , evaluateAndFormat
    , Format
    , format
    , Lint
    , lint
    , Freeze
    , freeze
      -- TODO bump
    }
