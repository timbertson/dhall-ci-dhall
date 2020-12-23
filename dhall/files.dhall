let Meta =
        env:DHALL_CI_META_OVERRIDE
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/master/Meta/package.dhall

in  { files =
        Meta.files
          Meta.Files::{
          , readme = Meta.Readme::{
            , repo = "dhall-ci-dhall"
            , componentDesc = Some "dhall support"
            }
          }
    }
