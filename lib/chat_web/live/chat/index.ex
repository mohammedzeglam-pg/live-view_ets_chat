defmodule ChatWeb.ChatLive.Index do
  use ChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"name" => ""}))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative overflow-hidden border shadow-sm rounded-xl bg-white  dark:bg-gray-800 dark:border-gray-700 dark:shadow-slate-700/[.7]">
      <div class="mx-auto max-w-screen-md py-12 px-4 sm:px-6 md:py-20 lg:py-32 md:px-8">
        <div class="md:pr-8 xl:pr-0">
          <h1 class="text-3xl text-gray-800 font-bold md:text-4xl md:leading-tight lg:text-5xl lg:leading-tight dark:text-gray-200">
            Join our awesome chat
          </h1>
          <p class="mt-3 text-base text-gray-500 mb-4">
            Completely secure no login no trackers, just chat with your freinds by share link.
          </p>
          <.login_form form={@form} />
        </div>
      </div>
    </div>
    """
  end

  attr :form, Phonenix.HTML.Form

  defp login_form(assigns) do
    ~H"""
    <.form :let={f} for={@form} class="flex flex-col gap-4" method="post" action={~p"/login"}>
      <label class="block text-sm font-medium dark:text-white">
        <span class="sr-only">Name</span>
        <input
          type="text"
          class="py-3 px-4 block w-full border-gray-200 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 sm:p-4 dark:bg-slate-900 dark:border-gray-700 dark:text-gray-400"
          placeholder="Name"
          name={f[:name].name}
        />
      </label>
      <div class="grid">
        <button
          type="submit"
          class="py-3 px-4 inline-flex justify-center items-center gap-2 rounded-md border border-transparent font-semibold bg-blue-500 text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm dark:focus:ring-offset-gray-800 sm:p-4"
        >
          Join
        </button>
      </div>
    </.form>
    """
  end
end
