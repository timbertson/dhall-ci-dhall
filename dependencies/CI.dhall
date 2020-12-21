    (   env:DHALL_CI_OVERRIDE
      ? https://raw.githubusercontent.com/timbertson/dhall-ci/master/package.dhall
    )
/\  { Git =
          env:DHALL_CI_GIT_OVERRIDE
        ? https://raw.githubusercontent.com/timbertson/dhall-ci-git/master/package.dhall
    }
