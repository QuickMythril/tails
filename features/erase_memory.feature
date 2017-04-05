@product
Feature: System memory erasure on shutdown
  As a Tails user
  when I shutdown Tails
  I want the system memory to be free from sensitive data.

# These tests rely on the Linux kernel's memory poisoning features.
# The feature is called "on shutdown" as this is the security guarantee
# we document, but in practice we have no good way to test behavior on shutdown
# per-se (known patterns allocated in memory will be erased _before_ shutdown
# by the kernel). So we test that some important bits of memory are erased
# _before_ shutdown.

  Scenario: Erasure of memory freed by a killed userspace process
    Given I have started Tails from DVD without network and logged in
    And I prepare Tails for memory erasure tests
    When I fill the guest's memory with a known pattern without verifying
    Then I find very few patterns in the guest's memory
