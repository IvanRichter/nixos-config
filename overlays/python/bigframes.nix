final: prev:
let
  inherit (final) fetchFromGitHub fetchPypi lib;
in
{
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pythonFinal: _pythonPrev: {
      google-cloud-bigquery-connection = pythonFinal.buildPythonPackage rec {
        pname = "google-cloud-bigquery-connection";
        version = "1.22.0";
        pyproject = true;

        src = fetchPypi {
          pname = "google_cloud_bigquery_connection";
          inherit version;
          hash = "sha256-E9uutA2xj5N88VIlOkXnonDAkMEr8mx5PEewpog3Rlg=";
        };

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
        version = "1.24.0";
        pyproject = true;

        src = fetchPypi {
          pname = "google_cloud_functions";
          inherit version;
          hash = "sha256-moOhdT+4i9pMLspBZ6fB4Bb5w2n7FaMwHZw4ln+2osM=";
        };

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

        src = fetchPypi {
          pname = "pandas_gbq";
          inherit version;
          hash = "sha256-NhPyA+CtnL44cJ/Lm0wsmvH9tGvtMzIZs0pjkUKFCAY=";
        };

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
          homepage = "https://github.com/googleapis/python-bigquery-pandas";
          license = licenses.bsd3;
        };
      };

      bigframes = pythonFinal.buildPythonPackage rec {
        pname = "bigframes";
        version = "2.48.0";
        pyproject = true;

        src = fetchFromGitHub {
          owner = "google";
          repo = "bigframes";
          rev = "7dd5232fae70802b335c6841066c3529f8a72e6e";
          hash = "sha256-Efi+qx4XrfwuSngcLBe7Bm9N7ansuRwWhXgop8dguf8=";
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
