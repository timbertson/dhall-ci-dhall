let Meta =
        env:DHALL_CI_META_OVERRIDE
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/e9f97f85078f4ec71ad7e00416f7a03ee14c40aa/Meta/package.dhall sha256:d456e4fad9f23f262dcc50fe0821ab83be6c8d40bbdc2784eec0812a3fa75fa9

in  { files =
        Meta.files
          Meta.Files::{
          , readme = Meta.Readme::{
            , repo = "dhall-ci-dhall"
            , componentDesc = Some "dhall support"
            }
          }
    }
