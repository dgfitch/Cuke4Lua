Feature: Run Lua step definitions from Cucumber

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/wired.feature" with:
      """
      Feature: So wired
        Scenario: Wired
          Given we're all wired

      """
    And a file named "features/step_definitions/some_remote_place.wire" with:
      """
      host: localhost
      port: 3901

      """
  
  Scenario: Dry run finds no step match
    Given Cuke4Lua started with no step definition modules
    When I run cucumber --dry-run -f progress features
    Then STDERR should be empty
    And it should pass with
      """
      U

      1 scenario (1 undefined)
      1 step (1 undefined)

      """
  
  Scenario: Dry run finds a step match
    Given Cuke4Lua started with a step definition module containing:
      """
      { AllWired = {
        Given = "^we're all wired$"
        Step = function()
        end
      } }
      """
    When I run cucumber --dry-run -f progress features  
    Then STDERR should be empty
    And it should pass with
      """
      -

      1 scenario (1 skipped)
      1 step (1 skipped)

      """

  Scenario: Invoke a step definition which passes
    Given Cuke4Lua started with a step definition module containing:
      """
      { AllWired = {
        Given = "^we're all wired$"
        Step = function()
        end
      } }
      """
    When I run cucumber -f progress features
    Then STDERR should be empty
    And it should pass with
      """
      .

      1 scenario (1 passed)
      1 step (1 passed)

      """
  
  Scenario: Invoke a step definition which passes, using pretty format
    Given Cuke4Lua started with a step definition module containing:
      """
      { AllWired = {
        Given = "^we're all wired$",
        Step = function()
        end
      } }
      """
    When I run cucumber --no-source -f pretty features
    Then STDERR should be empty
    And it should pass with
      """
      Feature: So wired

        Scenario: Wired
          Given we're all wired

      1 scenario (1 passed)
      1 step (1 passed)

      """
  
  Scenario: Invoke a step definition which fails
    Given Cuke4Lua started with a step definition module containing:
      """
      { AllWired = {
        Given = "^we're all wired$",
        Step = function()
          error "ouch"
        end
      } }
      """
    When I run cucumber -f progress features
    Then it should fail
