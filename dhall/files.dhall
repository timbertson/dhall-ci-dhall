let Meta =
        env:DHALL_CI_META_OVERRIDE
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/2c138742289b8d8466973d79ec8f666519a04520/Meta/package.dhall sha256:49c62308a660e31f5fa6cac67b328d45dd49a2a59ffafff896ef283c342203ec

in  { files =
        Meta.files
          Meta.Files::{
          , readme = Meta.Readme::{
            , repo = "dhall-ci-dhall"
            , componentDesc = Some "dhall support"
            }
          }
    }
