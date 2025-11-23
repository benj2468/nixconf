{ fetchFromGitLab, runCommand, mdbook }:
let
  src = fetchFromGitLab {
    protocol = "http";
    domain = "git.haganah.net";
    owner = "benj2468";
    repo = "bb-recipes";
    rev = "d3769e59219af3cb7cb37d28177c8cf6e70784a4";
    hash = "sha256-0BpLZL5luGeG04FrZXF0mmQ2NHpBgVds2Yt34UttX5g";
  };
in
runCommand "bb-recipes"
{
  nativeBuildInputs = [ mdbook ];
} ''
  mkdir $out

  cp -r ${src}/* ./

  mdbook build -d $out
''
