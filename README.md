# Abraxas Showcase

A Windows / WinForms / WebView2 walkthrough of public AbraxasDB APIs. The app contains runnable OSS lessons, complete copyable C# programs, graph inspection, indexes, selected-value reads, and memory-backed index examples.

Build with the .NET 10 SDK using `dotnet build src/AbraxasShowcase/AbraxasShowcase.csproj -c Release -p:Platform=x64`. This project consumes the public [AbraxasDB](https://github.com/alt160/AbraxasDB) NuGet package, which remains a .NET 8 library. A framework-dependent build requires the .NET 10 Windows Desktop runtime (x64) and WebView2 Evergreen runtime. Web content is bundled locally, including the pinned Monaco bundle and its license.

Download the Windows x64 ZIP from [Releases](https://github.com/alt160/AbraxasDB.Showcase/releases), extract the entire ZIP to a writable folder, and run `AbraxasShowcase.exe`.

The ZIP does not include .NET. Install the **.NET 10 Windows Desktop Runtime, x64**, from [Microsoft's .NET 10 downloads](https://dotnet.microsoft.com/en-us/download/dotnet/10.0#runtime-desktop-10.0.14) if it is not already installed. Choose **Desktop Runtime** rather than the standalone console or ASP.NET runtime. The app also requires [Microsoft Edge WebView2 Evergreen Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/). Neither prerequisite is installed automatically by this ZIP.

The first standalone release is being validated; the release link will become available when publication completes.

Run `AbraxasShowcase.exe --data "T:\AbraxasShowcaseDemo"` to choose a dedicated laboratory. Group setup can replace data inside its app-owned laboratory after confirmation; do not use an application database as a laboratory. The default laboratory is under the current user's LocalApplicationData directory.

Commercial feature examples remain readable. OSS execution shows an edition notice and does not run commercial engine code. Private verification, named-pipe UI probes, profiling tools and commercial implementations are excluded from this distribution.

`--export-examples --output "T:\AbraxasExamples"` writes standalone example programs to a chosen new output folder. Commercial-only examples are marked as requiring the separate commercial edition.
