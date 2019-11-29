defmodule MakingIllegalStatesUnrepresentableTest do
  use ExUnit.Case
  use Typist

  # https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/#making-illegal-states-unrepresentable

  describe "making illegal states unrepresentable" do
    deftype PersonalName do
      first_name :: String.t()
      middle_initial :: Maybe.t(String.t())
      last_name :: String.t()
    end

    defmodule EmailAddress do
      deftype String.t()

      @spec new(String.t()) :: t
      def new(s) do
        if Regex.match?(~r/^\S+@\S+\.\S+$/, s) do
          s
          |> super
          |> Maybe.some()
        else
          Maybe.none()
        end
      end
    end

    deftype EmailContactInfo do
      email_address :: EmailAddress.t()
      is_email_verified :: boolean
    end

    deftype ZipCode :: String.t()
    deftype StateCode :: String.t()

    deftype PostalAddress do
      address_1 :: String.t()
      address_2 :: String.t()
      city :: String.t()
      state :: StateCode.t()
      zip :: ZipCode.t()
    end

    deftype PostalContactInfo do
      address :: PostalAddress.t()
      is_address_valid :: boolean
    end

    # type ContactInfo =
    #   | EmailOnly of EmailContactInfo
    #   | PostOnly of PostalContactInfo
    #   | EmailAndPost of EmailContactInfo * PostalContactInfo
    #
    # type Contact =
    #     {
    #     Name: Name;
    #     ContactInfo: ContactInfo;
    #     }

    deftype ContactInfo do
      EmailOnly ::
        EmailContactInfo.t()
        | PostOnly ::
        PostalContactInfo.t()
        | EmailAndPost :: {EmailContactInfo.t(), PostalContactInfo.t()}
    end

    deftype Contact do
      name :: PersonalName.t()
      contact_info :: ContactInfo.t()
    end

    # https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/#constructing-a-contactinfo

    # let contactFromEmail name emailStr =
    #     let emailOpt = EmailAddress.create emailStr
    #     // handle cases when email is valid or invalid
    #     match emailOpt with
    #     | Some email ->
    #         let emailContactInfo =
    #             {EmailAddress=email; IsEmailVerified=false}
    #         let contactInfo = EmailOnly emailContactInfo
    #         Some {Name=name; ContactInfo=contactInfo}
    #     | None -> None

    def contact_from_email(name, email_str) do
      email_opt = EmailAddress.new(email_str)

      case email_opt do
        {:some, email} ->
          email_contact_info =
            EmailContactInfo.new(%{email_address: email, is_email_verified: false})

          contact_info = EmailOnly.new(email_contact_info)
          Maybe.some(Contact.new(%{name: name, contact_info: contact_info}))

        :none ->
          Maybe.none()
      end
    end

    test "constructing a contact info" do
      name = PersonalName.new(%{first_name: "A", middle_initial: Maybe.none(), last_name: "Smith"})
      contact_opt = contact_from_email(name, "abc@example.com")

      assert {:some, %{contact_info: %{value: %{email_address: %{value: "abc@example.com"}}}}} =
               contact_opt
    end

    # https://fsharpforfunandprofit.com/posts/designing-with-types-making-illegal-states-unrepresentable/#updating-a-contactinfo

    # let updatePostalAddress contact newPostalAddress =
    #     let {Name=name; ContactInfo=contactInfo} = contact
    #     let newContactInfo =
    #         match contactInfo with
    #         | EmailOnly email ->
    #             EmailAndPost (email,newPostalAddress)
    #         | PostOnly _ -> // ignore existing address
    #             PostOnly newPostalAddress
    #         | EmailAndPost (email,_) -> // ignore existing address
    #             EmailAndPost (email,newPostalAddress)
    #     // make a new contact
    #     {Name=name; ContactInfo=newContactInfo}

    def update_postal_address(contact, new_postal_address) do
      %{name: name, contact_info: contact_info} = contact

      new_contact_info =
        case contact_info do
          %EmailOnly{} = email ->
            EmailAndPost.new({email, new_postal_address})

          %PostOnly{} ->
            PostOnly.new(new_postal_address)

          %EmailAndPost{value: {email, _}} ->
            EmailAndPost.new({email, new_postal_address})
        end

      ContactInfo.new(%{name: name, contact_info: new_contact_info})
    end

    test "updating a contact" do
      name = PersonalName.new(%{first_name: "A", middle_initial: Maybe.none(), last_name: "Smith"})
      {:some, contact} = contact_from_email(name, "abc@example.com")
      state = StateCode.new("CA")
      zip = ZipCode.new("97210")

      address =
        PostalAddress.new(%{
          address_1: "123 Main",
          address_2: "",
          city: "Beverly Hills",
          state: state.value,
          zip: zip.value
        })

      new_postal_address = PostalContactInfo.new(%{address: address, is_address_valid: false})

      new_contact = update_postal_address(contact, new_postal_address)
      assert %EmailAndPost{} = new_contact.contact_info
    end
  end
end
