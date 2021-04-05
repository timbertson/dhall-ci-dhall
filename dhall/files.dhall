let Meta = ./Meta.dhall

in  { files =
        Meta.files
          Meta.Files::{
          , readme = Meta.Readme::{
            , repo = "dhall-ci-dhall"
            , componentDesc = Some "dhall support"
            }
          }
    }
