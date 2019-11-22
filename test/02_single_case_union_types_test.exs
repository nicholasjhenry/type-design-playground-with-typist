defmodule SingleCaseUntionTypesTest do
  use ExUnit.Case
  use Typist

  # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/

  describe "wrapping primitive types" do
    # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#wrapping-primitive-types
    #
    # type PersonalName =
    #     {
    #     FirstName: string;
    #     MiddleInitial: string option;
    #     LastName: string;
    #     }
    #
    # type EmailAddress = EmailAddress of string
    #
    # type EmailContactInfo =
    #     {
    #     EmailAddress: EmailAddress;
    #     IsEmailVerified: bool;
    #     }
    #
    # type ZipCode = ZipCode of string
    # type StateCode = StateCode of string
    #
    # type PostalAddress =
    #     {
    #     Address1: string;
    #     Address2: string;
    #     City: string;
    #     State: StateCode;
    #     Zip: ZipCode;
    #     }
    #
    # type PostalContactInfo =
    #     {
    #     Address: PostalAddress;
    #     IsAddressValid: bool;
    #     }
    #
    # type Contact =
    #     {
    #     Name: PersonalName;
    #     EmailContactInfo: EmailContactInfo;
    #     PostalContactInfo: PostalContactInfo;
    #     }

    deftype PersonalName do
      first_name :: String.t()
      middle_initial :: Maybe.t(String.t())
      last_name :: String.t()
    end

    deftype EmailAddress :: String.t()

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

    deftype Contact do
      name :: PersonalName.t()
      email_contact_info :: EmailContactInfo.t()
      personal_contact_info :: PersonalContactInfo.t()
    end

    # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#constructing-single-case-unions

    # let CreateEmailAddress (s:string) =
    #   if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
    #       then Some (EmailAddress s)
    #       else None
    #
    # let CreateStateCode (s:string) =
    #     let s' = s.ToUpper()
    #     let stateCodes = ["AZ";"CA";"NY"] //etc
    #     if stateCodes |> List.exists ((=) s')
    #         then Some (StateCode s')
    #         else None
    #
    def create_email_address(s) do
      if Regex.match?(~r/^\S+@\S+\.\S+$/, s) do
        s
        |> EmailAddress.new()
        |> Maybe.some()
      else
        Maybe.none()
      end
    end

    def create_state_code(s) do
      s = String.upcase(s)
      state_codes = ["AZ", "CA", "NY"]

      if s in state_codes do
        s
        |> StateCode.new()
        |> Maybe.some()
      else
        Maybe.none()
      end
    end

    # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#constructing-single-case-unions
    test "constructing single case unions" do
      assert {:some, %{value: "CA"}} = create_state_code("CA")
      assert :none = create_state_code("XX")

      assert {:some, %{value: "a@example.com"}} = create_email_address("a@example.com")
      assert :none = create_email_address("example.com")
    end

    # type CreationResult<'T> = Success of 'T | Error of string
    #
    # let CreateEmailAddress2 (s:string) =
    #     if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
    #         then Success (EmailAddress s)
    #         else Error "Email address must contain an @ sign"

    defmodule CreationResult do
      deftype {:ok, any} | {:error, any}

      def ok(value), do: {:ok, value}
      def error(msg), do: {:error, msg}
    end

    def create_email_address_2(s) do
      if Regex.match?(~r/^\S+@\S+\.\S+$/, s) do
        s
        |> EmailAddress.new()
        |> CreationResult.ok()
      else
        CreationResult.error("Email address must contain an @ sign")
      end
    end

    # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#handling-invalid-input-in-a-constructor
    test "handling invalid input in a constructor" do
      assert {:error, _} = create_email_address_2("example.com")
    end

    # let CreateEmailAddressWithContinuations success failure (s:string) =
    #     if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
    #         then success (EmailAddress s)
    #         else failure "Email address must contain an @ sign"

    def create_email_address_with_continuations(success, failure, s) do
      if Regex.match?(~r/^\S+@\S+\.\S+$/, s) do
        s
        |> EmailAddress.new()
        |> success.()
      else
        failure.("Email address must contain an @ sign")
      end
    end

    # let success (EmailAddress s) = printfn "success creating email %s" s
    # let failure  msg = printfn "error creating email: %s" msg

    def success(%EmailAddress{value: s}), do: IO.puts("success creating email #{s}")
    def failure(msg), do: IO.puts("error creating email: #{msg}")

    import ExUnit.CaptureIO, only: [capture_io: 1]

    test "with continuations" do
      assert "error creating email: Email address must contain an @ sign\n" ==
               capture_io(fn ->
                 create_email_address_with_continuations(&success/1, &failure/1, "example.com")
               end)

      assert "success creating email a@example.com\n" ==
               capture_io(fn ->
                 create_email_address_with_continuations(&success/1, &failure/1, "a@example.com")
               end)
    end

    test "with continuations with Maybe.t/1" do
      success = &Maybe.some/1
      failure = fn _ -> Maybe.none() end

      assert :none = create_email_address_with_continuations(success, failure, "example.com")

      assert {:some, %EmailAddress{}} =
               create_email_address_with_continuations(success, failure, "a@example.com")
    end

    test "with continuations with exception" do
      success = & &1
      failure = fn _ -> raise "bad email address" end

      assert_raise RuntimeError, "bad email address", fn ->
        create_email_address_with_continuations(success, failure, "example.com")
      end

      assert %EmailAddress{} =
               create_email_address_with_continuations(success, failure, "a@example.com")
    end

    test "with continuations with partially applied" do
      success = &Maybe.some/1
      failure = fn _ -> Maybe.none() end
      create_email = &create_email_address_with_continuations(success, failure, &1)

      assert :none = create_email.("example.com")
      assert {:some, %EmailAddress{}} = create_email.("a@example.com")
    end
  end

  describe "creating modules for wrapper types" do
    # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#creating-modules-for-wrapper-types
    #
    # module EmailAddress =
    #   type T = EmailAddress of string
    #
    #   // wrap
    #   let create (s:string) =
    #       if System.Text.RegularExpressions.Regex.IsMatch(s,@"^\S+@\S+\.\S+$")
    #           then Some (EmailAddress s)
    #           else None
    #
    #   // unwrap
    #   let value (EmailAddress e) = e

    defmodule EmailAddress2 do
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

      # value/1 and apply/2 are generated
    end

    test "construction" do
      address_1 = EmailAddress2.new("a@example.com")
      _address_2 = EmailAddress2.new("example.com")

      result =
        case address_1 do
          {:some, e} ->
            "the value is #{EmailAddress2.value(e)}"

          :none ->
            ""
        end

      assert result == "the value is a@example.com"
    end

    # https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/#when-to-unwrap-single-case-unions
    #
    # > It is surprisingly uncommon that you actually need the wrapped contents directly when
    # > working in the domain itself.

    test "unwrapping" do
      {:some, address} = EmailAddress2.new("a@example.com")

      assert "the value is a@example.com" == "the value is #{EmailAddress2.value(address)}"
      assert "the value is a@example.com" == EmailAddress2.apply(address, &"the value is #{&1}")
    end
  end
end
