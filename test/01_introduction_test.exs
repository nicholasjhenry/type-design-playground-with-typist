defmodule IntroductionTest do
  use ExUnit.Case
  use Typist

  # https://fsharpforfunandprofit.com/posts/designing-with-types-intro/

  describe "a basic example" do
    # F# example:
    #
    # type Contact =
    #   {
    #   FirstName: string;
    #   MiddleInitial: string;
    #   LastName: string;
    #
    #   EmailAddress: string;
    #   //true if ownership of email address is confirmed
    #   IsEmailVerified: bool;
    #
    #   Address1: string;
    #   Address2: string;
    #   City: string;
    #   State: string;
    #   Zip: string;
    #   //true if validated against address service
    #   IsAddressValid: bool;
    #   }

    deftype Contact do
      first_name :: String.t()
      middle_initial :: String.t()
      last_name :: String.t()

      email_address :: String.t()
      is_email_verified :: String.t()

      address_1 :: String.t()
      address_2 :: String.t()
      city :: String.t()
      state :: String.t()
      zip :: String.t()
      is_address_valid :: boolean
    end

    test "contact" do
      Contact.new(%{
        first_name: Faker.Name.first_name(),
        middle_initial: Faker.Util.letter(),
        last_name: Faker.Name.last_name(),
        email_address: Faker.Internet.email(),
        is_email_verified: true,
        address_1: Faker.Address.street_address(),
        address_2: Faker.Address.secondary_address(),
        city: Faker.Address.city(),
        state: Faker.Address.state(),
        zip: Faker.Address.zip(),
        is_address_valid: true
      })
    end
  end

  describe "atomic types" do
    # type PostalAddress =
    #   {
    #   Address1: string;
    #   Address2: string;
    #   City: string;
    #   State: string;
    #   Zip: string;
    #   }
    #
    # type PostalContactInfo =
    #   {
    #   Address: PostalAddress;
    #   IsAddressValid: bool;
    #   }

    deftype PostalAddress do
      address_1 :: String.t()
      address_2 :: String.t()
      city :: String.t()
      state :: String.t()
      zip :: String.t()
    end

    deftype PostalContactInfo do
      address :: PostalAddress.t()
      is_address_valid :: boolean
    end

    test "postal contact info" do
      postal_address =
        PostalAddress.new(%{
          address_1: Faker.Address.street_address(),
          address_2: Faker.Address.secondary_address(),
          state: Faker.Address.state(),
          city: Faker.Address.city(),
          zip: Faker.Address.zip()
        })

      PostalContactInfo.new(%{address: postal_address, is_address_valid: true})
    end

    # type PersonalName =
    #   {
    #   FirstName: string;
    #   // use "option" to signal optionality
    #   MiddleInitial: string option;
    #   LastName: string;
    #   }

    deftype PersonalName do
      first_name :: String.t()
      middle_initial :: String.t()
      last_name :: String.t()
    end

    test "personal name" do
      PersonalName.new(%{
        first_name: Faker.Name.first_name(),
        middle_initial: Faker.Util.letter(),
        last_name: Faker.Name.last_name()
      })
    end
  end
end
