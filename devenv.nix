{ pkgs, lib, config, inputs, ... }:

{

  # https://devenv.sh/basics/
  env = {
    GREET = "devenv";
    # Ensure Chrome runs in headless mode for CI
    CHROME_BIN = "${pkgs.google-chrome}/bin/google-chrome-stable";
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "true";
    PUPPETEER_EXECUTABLE_PATH =
      "${pkgs.google-chrome}/bin/google-chrome-stable";

    # Dagger configuration
    DAGGER_ENGINE_VERSION = "v0.9.0";

    # Project info
    PROJECT_NAME = "tracker-blocker-extension";
  };

  # https://devenv.sh/packages/
  # SonarQube needs nodejs 18.17 or later
  packages = with pkgs; [
    # Core development tools
    nodejs_20
    go
    git
    # Chrome extension development
    google-chrome
    chromium

    # Utilities
    zip
    unzip
    curl
    wget
    jq
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  scripts = {
    # Initialize Dagger module (one-time setup)
    init-dagger.exec = ''
      echo "🚀 Initializing Dagger module..."

      # Create dagger directory if it doesn't exist
      mkdir -p dagger

      # Initialize Dagger module
      dagger init --name=tracker-blocker-test --sdk=go

      # Create the pipeline file
      cat > dagger/main.go << 'EOF'
        ${builtins.readFile ./dagger-pipeline.go}
      EOF

      # Initialize Go module
      cd dagger
      go mod init tracker-blocker-test
      go mod tidy
      cd ..

      echo "✅ Dagger module initialized!"
      echo "Run 'test-extension' to run tests"
    '';

    # Run extension tests
    test-extension.exec = ''
      echo "🧪 Running Chrome Extension Tests..."

      # Ensure dagger module exists
      if [ ! -f "dagger/main.go" ]; then
        echo "❌ Dagger module not found. Run 'init-dagger' first."
        exit 1
      fi

      # Run the tests
      dagger call test-extension --source=.
    '';

    # Generate test report
    generate-report.exec = ''
      echo "📊 Generating test report..."

      # Generate HTML report
      dagger call generate-report --source=. > test-report.html

      # Generate JSON results
      mkdir -p test-results
      dagger call get-test-results --source=. --output=./test-results

      echo "✅ Reports generated:"
      echo "  📄 HTML: test-report.html"
      echo "  📁 JSON: test-results/"

      # Open report in browser if available
      if command -v xdg-open > /dev/null; then
        xdg-open test-report.html
      elif command -v open > /dev/null; then
        open test-report.html
      fi
    '';

    # Build extension for distribution
    build-extension.exec = ''
      echo "📦 Building extension for distribution..."

      # Create dist directory
      mkdir -p dist

      # Copy extension files
      cp manifest.json dist/
      cp background.js dist/
      cp tracker-block-extension.js dist/
      cp tracking-blocker.js dist/
      cp tracker-urls.txt dist/

      # Create zip file
      cd dist
      zip -r ../tracker-blocker-extension.zip .
      cd ..

      echo "✅ Extension built: tracker-blocker-extension.zip"
    '';

    # Complete CI/CD pipeline (build + test + report)
    ci.exec = ''
      echo "🔄 Running complete CI/CD pipeline..."

      # Initialize if needed
      if [ ! -f "dagger/main.go" ]; then
        init-dagger
      fi

      # Build extension
      build-extension

      # Run tests
      test-extension

      # Generate reports
      generate-report

      echo "🎉 CI/CD pipeline completed successfully!"
    '';

    # Development server with file watching
    dev.exec = ''
      echo "🔧 Starting development mode..."
      echo "Extension files are being watched for changes..."

      # Use nodemon to watch for changes and rebuild
      npx nodemon --watch . --ext js,json,txt --ignore node_modules --ignore test-results --ignore dist --exec "echo '🔄 Files changed, rebuilding...' && build-extension"
    '';

    # Clean up generated files
    clean.exec = ''
      echo "🧹 Cleaning up generated files..."
      rm -rf dist/
      rm -rf test-results/
      rm -f test-report.html
      rm -f tracker-blocker-extension.zip
      echo "✅ Cleanup completed!"
    '';
  };
  processes = {
    # Optional: Run a simple HTTP server for testing
    http-server = {
      exec = "npx http-server . -p 8080 -c-1";
      process-compose = {
        availability = {
          restart = "on_failure";
          max_restarts = 3;
        };
      };
    };
  };

  enterShell = ''
    hello
    git --version

    if [ ! -f package.json ]; then
      echo "Initializing npm project"
      npm init -y
    fi

    if ! grep -q puppeteer package.json; then
      echo "Installing Puppeteer..."
      npm install --save-dev puppeteer
    fi

    echo "🛡️  Tracker Blocker Extension Development Environment"
    echo "=================================================="
    echo ""
    echo "Available commands:"
    echo "  🚀 init-dagger     - Initialize Dagger testing pipeline"
    echo "  🧪 test-extension  - Run Chrome extension tests"
    echo "  📊 generate-report - Generate HTML/JSON test reports"
    echo "  📦 build-extension - Build extension for distribution"
    echo "  🔄 ci             - Run complete CI/CD pipeline"
    echo "  🔧 dev            - Start development mode with file watching"
    echo "  🧹 clean          - Clean up generated files"
    echo ""
    echo "Project structure:"
    echo "  📁 Extension files: manifest.json, *.js, tracker-urls.txt"
    echo "  📁 Tests: tests/e2e-tracker-url.test.js"
    echo "  📁 Build output: dist/"
    echo "  📁 Test results: test-results/"
    echo ""

    # Check if this is first run
    if [ ! -f "dagger/main.go" ]; then
      echo "⚠️  First time setup detected!"
      echo "Run 'init-dagger' to set up the testing pipeline."
      echo ""
    fi

    # Show current project status
    echo "Current project status:"
    if [ -f "manifest.json" ]; then
      echo "  ✅ Extension manifest found"
    else
      echo "  ❌ Extension manifest missing"
    fi

    if [ -f "dagger/main.go" ]; then
      echo "  ✅ Dagger pipeline configured"
    else
      echo "  ⚠️  Dagger pipeline not initialized (run 'init-dagger')"
    fi

    if [ -d "node_modules" ]; then
      echo "  ✅ Dependencies installed"
    else
      echo "  ⚠️  Dependencies not installed (run 'npm install')"
    fi

    echo ""
  '';

  # Git hooks for quality assurance
  git-hooks = {
    hooks.test-extension = {
      enable = true;
      entry = "${pkgs.writeShellScript "test-extension" ''
        if [ -f "dagger/main.go" ]; then
          echo "Running extension tests before commit..."
          dagger call -vvv test-extension --source=.
        else
          echo "Dagger not initialized, skipping tests"
        fi
      ''}";
      files = "\\.(js|json|txt)$";
    };
  };

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
