# liveview-native-swiftui-google-sign-in

## About

`liveview-native-swiftui-google-sign-in` is an add-on library for [LiveView Native](https://github.com/liveview-native/live_view_native). It adds [Google Sign In](https://developers.google.com/identity/sign-in/ios/sign-in) support.

## Installation

1. Add this library as a package to your LiveView Native application's Xcode project
    * In Xcode, select *File* → *Add Packages...*
    * Enter the package URL `https://github.com/michaelst/liveview-native-swiftui-google-sign-in`
    * Select *Add Package*

## Usage

When using Swift 5.9+, add the `GoogleSignInRegistry` to the `addons` list of your `#LiveView`.

```swift
import SwiftUI
import LiveViewNative
import LiveViewNativeGoogleSignIn // 1. Import the add-on library.

struct ContentView: View {
    var body: some View {
        #LiveView(
          .localhost,
          addons: [GoogleSignInRegistry<_>.self] // 2. Include the `GoogleSignInRegistry`.
        )
    }
}
```

To render a Google sign in button, use the `GoogleSignInButton` element. You can pass an `onSignIn` event handler to receive the `id_token` from Google.

```elixir
def render(assigns, _interface) do
  ~LVN"""
  <GoogleSignInButton onSignIn="google_signin"/>
  """
end

def handle_event("google_signin", %{"id_token" => id_token}, socket) do
  client_id = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)[:client_id]

  # make sure audience is your client_id to prevent an attacker using a token from another app
  case MyApp.Guardian.decode_and_verify(id_token, %{"aud" => client_id}) do
    {:ok, %{"sub" => uid}} ->
      user = MyApp.get_user(uid)

      token = Phoenix.Token.sign(MyAppWeb.Endpoint, "user", user_id)

      {:noreply, push_redirect(socket, to: ~p"/page?token=#{token}", replace: true)}

    {:error, _reason} ->
      {:noreply, socket}
  end
end
```

Example config and keyserver to use with Guardian for verifying Google tokens:

```elixir
# in config/config.exs
config :my_app, MyApp.Guardian,
  issuer: "https://accounts.google.com",
  verify_issuer: true,
  ttl: {1, :hour},
  allowed_algos: ["RS256"],
  secret_fetcher: MyApp.Guardian.KeyServer

# in lib/my_app/guardian/key_server.ex
defmodule MyApp.Guardian.KeyServer do
  @behaviour Guardian.Token.Jwt.SecretFetcher

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    :ets.new(__MODULE__, [:named_table, :public])
    {:ok, nil}
  end

  @impl Guardian.Token.Jwt.SecretFetcher
  def fetch_signing_secret(_mod, _opts), do: {:error, :not_supported}

  @impl Guardian.Token.Jwt.SecretFetcher
  def fetch_verifying_secret(_mod, %{"kid" => kid}, _opts) do
    case lookup(kid) do
      {:ok, jwk} ->
        {:ok, jwk}

      :error ->
        load_public_keys()
        lookup(kid)
    end
  end

  defp lookup(kid) do
    case :ets.lookup(__MODULE__, kid) do
      [{^kid, key}] -> {:ok, key}
      [] -> :error
    end
  end

  defp load_public_keys() do
    {:ok, %{body: body}} = Tesla.get("https://www.googleapis.com/oauth2/v3/certs")
    %{"keys" => public_keys} = Jason.decode!(body)

    Enum.each(public_keys, fn %{"kid" => kid} = key ->
      :ets.insert(__MODULE__, {kid, JOSE.JWK.from(key)})
    end)
  end
end
```