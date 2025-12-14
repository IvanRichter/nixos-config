final: prev:
let
  inherit (final) fetchFromGitHub lib;
in {
  pythonPackagesExtensions =
    (prev.pythonPackagesExtensions or [])
    ++ [
      (pythonFinal: pythonPrev: {
        bigquery-magics = pythonFinal.buildPythonPackage rec {
          pname = "bigquery-magics";
          version = "0.10.3";
          format = "setuptools";

          src = fetchFromGitHub {
            owner = "googleapis";
            repo = "python-bigquery-magics";
            rev = "09b65f9550ad8216ddb27af0fd0d4d0319ed7b2f";
            hash = "sha256-F8yMAJahehV50MKbijIq3YZBsN6kv7xo0mQsYbg3el8=";
          };

          propagatedBuildInputs = with pythonPrev; [
            db-dtypes
            google-cloud-bigquery
            ipykernel
            ipython
            ipywidgets
            packaging
            pandas
            pyarrow
            pydata-google-auth
            tqdm
          ];

          pythonImportsCheck = [ "bigquery_magics" ];
          doCheck = false;

          meta = with lib; {
            description = "IPython Magics for BigQuery";
            homepage = "https://github.com/googleapis/python-bigquery-magics";
            license = licenses.asl20;
          };
        };
      })
    ];
}
