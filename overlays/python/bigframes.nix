final: prev:
let
  inherit (final) fetchFromGitHub lib;
in
{
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pythonFinal: _pythonPrev: {
      google-cloud-bigquery-connection = pythonFinal.buildPythonPackage rec {
        pname = "google-cloud-bigquery-connection";
        version = "1.23.0";
        pyproject = true;

        src = fetchFromGitHub {
          owner = "googleapis";
          repo = "google-cloud-python";
          tag = "${pname}-v${version}";
          hash = "sha256-b0FYupZU0ZNeIL9xJIqEXgg7ToRCQLjiswJ67YzX7OI=";
        };

        sourceRoot = "${src.name}/packages/${pname}";

        build-system = [ pythonFinal.setuptools ];

        dependencies =
          with pythonFinal;
          [
            google-api-core
            google-auth
            grpc-google-iam-v1
            proto-plus
            protobuf
          ]
          ++ google-api-core.optional-dependencies.grpc;

        pythonImportsCheck = [ "google.cloud.bigquery_connection_v1" ];
        doCheck = false;

        meta = with lib; {
          description = "Google Cloud BigQuery Connection API client library";
          homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/google-cloud-bigquery-connection";
          license = licenses.asl20;
        };
      };

      google-cloud-functions = pythonFinal.buildPythonPackage rec {
        pname = "google-cloud-functions";
        version = "1.25.0";
        pyproject = true;

        src = fetchFromGitHub {
          owner = "googleapis";
          repo = "google-cloud-python";
          tag = "${pname}-v${version}";
          hash = "sha256-b0FYupZU0ZNeIL9xJIqEXgg7ToRCQLjiswJ67YzX7OI=";
        };

        sourceRoot = "${src.name}/packages/${pname}";

        build-system = [ pythonFinal.setuptools ];

        dependencies =
          with pythonFinal;
          [
            google-api-core
            google-auth
            grpc-google-iam-v1
            proto-plus
            protobuf
          ]
          ++ google-api-core.optional-dependencies.grpc;

        pythonImportsCheck = [
          "google.cloud.functions_v1"
          "google.cloud.functions_v2"
        ];
        doCheck = false;

        meta = with lib; {
          description = "Google Cloud Functions API client library";
          homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/google-cloud-functions";
          license = licenses.asl20;
        };
      };

      pandas-gbq = pythonFinal.buildPythonPackage rec {
        pname = "pandas-gbq";
        version = "0.35.2";
        pyproject = true;

        src = fetchFromGitHub {
          owner = "googleapis";
          repo = "google-cloud-python";
          tag = "${pname}-v${version}";
          hash = "sha256-0g0uTpt03BrFLJ7vGptrUy3pVx8EAOKYV+uB2bJTJNQ=";
        };

        sourceRoot = "${src.name}/packages/${pname}";

        build-system = [ pythonFinal.setuptools ];

        dependencies = with pythonFinal; [
          db-dtypes
          google-api-core
          google-auth
          google-auth-oauthlib
          google-cloud-bigquery
          numpy
          packaging
          pandas
          psutil
          pyarrow
          pydata-google-auth
          setuptools
        ];

        pythonImportsCheck = [ "pandas_gbq" ];
        doCheck = false;

        meta = with lib; {
          description = "Pandas interface for querying and loading data into BigQuery";
          homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/pandas-gbq";
          license = licenses.bsd3;
        };
      };

      bigframes = pythonFinal.buildPythonPackage rec {
        pname = "bigframes";
        version = "2.50.0";
        pyproject = true;

        src = fetchFromGitHub {
          owner = "google";
          repo = "bigframes";
          rev = "54b12595258f75de3869442c16c3705737fe7bf0";
          hash = "sha256-+jPwPptIL0jZ3OASFoPTM1QU+ozDMo1RQg8lwnV66+c=";
        };

        build-system = [ pythonFinal.setuptools ];

        dependencies = with pythonFinal; [
          atpublic
          cloudpickle
          db-dtypes
          fsspec
          gcsfs
          geopandas
          google-auth
          google-cloud-bigquery
          google-cloud-bigquery-connection
          google-cloud-bigquery-storage
          google-cloud-functions
          google-cloud-resource-manager
          google-cloud-storage
          google-crc32c
          grpc-google-iam-v1
          humanize
          matplotlib
          numpy
          packaging
          pandas
          pandas-gbq
          pyarrow
          pydata-google-auth
          pyiceberg
          pyopenssl
          python-dateutil
          pytz
          requests
          rich
          shapely
          tabulate
          toolz
          typing-extensions
        ];

        pythonRelaxDeps = [ "rich" ];

        pythonImportsCheck = [ "bigframes" ];
        doCheck = false;

        meta = with lib; {
          description = "BigQuery DataFrames for scalable analytics and machine learning";
          homepage = "https://github.com/google/bigframes";
          license = licenses.asl20;
        };
      };
    })
  ];
}
