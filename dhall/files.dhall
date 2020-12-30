let Meta =
        env:DHALL_CI_META_OVERRIDE
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/e6cb50732b6f448513d252416abcfb3cc8f0a804/Meta/package.dhall sha256:c9f060248aa9ebac979cf3b50143c34b6cc5c7ff33804d80eff5d15e85c5b073

in  { files =
        Meta.files
          Meta.Files::{
          , readme = Meta.Readme::{
            , repo = "dhall-ci-dhall"
            , componentDesc = Some "dhall support"
            }
          }
    }
