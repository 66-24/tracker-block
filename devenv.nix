{ pkgs, lib, config, inputs, ... }:

{

  # https://devenv.sh/basics/
  env = {
    GREET = "devenv";
    PROJECT_NAME = "tracker-blocker-extension";
  };

  # https://devenv.sh/packages/
  # SonarQube needs nodejs 18.17 or later
  packages = with pkgs; [
    # Core development tools
    nodejs_20
    go

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

      dagger init --name=tracker-blocker-test --sdk=go


      # Initialize Go module
      cd .dagger
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
      if [ ! -f ".dagger/main.go" ]; then
        echo "❌ Dagger module not found. Run 'init-dagger' first."
        exit 1
      fi

      # Run the tests
      # `src` is of type  directory and is a parameter to the TextExtension Go function
      dagger call test-extension --src=.
    '';

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
    if [ -f "extension/manifest.json" ]; then
      echo "  ✅ Extension manifest found"
    else
      echo "  ❌ Extension manifest missing"
    fi

    if [ -f ".dagger/main.go" ]; then
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
        if [ -f ".dagger/main.go" ]; then
          echo "Running extension tests before commit..."
          dagger call test-extension --src=.
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
