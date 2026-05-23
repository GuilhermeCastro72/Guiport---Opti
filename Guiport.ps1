<#
.SYNOPSIS
    Guiport PC Optimizer
.DESCRIPTION
    Ferramenta de otimizacao de PC para Windows
    Baseada na arquitetura do WinUtil de Chris Titus Tech
.NOTES
    Executar com:
        irm https://raw.githubusercontent.com/GuilhermeCastro72/Guiport---Opti/main/Guiport.ps1 | iex
    Ou localmente:
        powershell -ExecutionPolicy Bypass -File Guiport.ps1
#>

# ─── Auto-elevacao ────────────────────────────────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  Guiport requer privilegios de Administrador. A reiniciar..." -ForegroundColor Yellow
    $script = if ($PSCommandPath) {
        "& { & '$($PSCommandPath)' }"
    } else {
        "&([ScriptBlock]::Create((irm https://raw.githubusercontent.com/GuilhermeCastro72/Guiport---Opti/main/Guiport.ps1)))"
    }
    $cmd = if (Get-Command pwsh -EA SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process $cmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    exit
}

# ─── Assemblies ───────────────────────────────────────────────────────────────
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

# ─── Sync hashtable (partilhado entre runspaces) ─────────────────────────────
$sync = [Hashtable]::Synchronized(@{})
$sync.ProcessRunning = $false

# ─── Logo ASCII ───────────────────────────────────────────────────────────────
function Show-GuiportLogo {
    Clear-Host
    Write-Host ""
    Write-Host "   ██████╗ ██╗   ██╗██╗██████╗  ██████╗ ██████╗ ████████╗" -ForegroundColor Yellow
    Write-Host "  ██╔════╝ ██║   ██║██║██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝" -ForegroundColor Yellow
    Write-Host "  ██║  ███╗██║   ██║██║██████╔╝██║   ██║██████╔╝   ██║   " -ForegroundColor Yellow
    Write-Host "  ██║   ██║██║   ██║██║██╔═══╝ ██║   ██║██╔══██╗   ██║   " -ForegroundColor Yellow
    Write-Host "  ╚██████╔╝╚██████╔╝██║██║     ╚██████╔╝██║  ██║   ██║   " -ForegroundColor Yellow
    Write-Host "   ╚═════╝  ╚═════╝ ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝  " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  PC Optimizer  -  Inspirado no WinUtil de Chris Titus Tech" -ForegroundColor DarkGray
    Write-Host ""
}

Show-GuiportLogo

# ─── Runspace helper ─────────────────────────────────────────────────────────
function Invoke-GuiportRunspace {
    param([ScriptBlock]$ScriptBlock, [string]$ArgumentList)
    $ps = [powershell]::Create()
    $ps.Runspace = $sync.runspace
    [void]$ps.AddScript($ScriptBlock)
    if ($ArgumentList) { [void]$ps.AddArgument($ArgumentList) }
    $handle = $ps.BeginInvoke()
    return @{ handle = $handle; ps = $ps }
}

# ─── Registry helper ─────────────────────────────────────────────────────────
function Set-GuiportRegistry {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

# ─── XAML ─────────────────────────────────────────────────────────────────────
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Guiport PC Optimizer"
    WindowStartupLocation="CenterScreen"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    Width="1100" Height="720"
    MinWidth="900" MinHeight="580">

    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" ResizeBorderThickness="5" CornerRadius="12"/>
    </WindowChrome.WindowChrome>

    <Window.Resources>
        <!-- CORES -->
        <Color x:Key="BgColor">#0C0C0C</Color>
        <Color x:Key="Bg1Color">#131313</Color>
        <Color x:Key="Bg2Color">#1A1A1A</Color>
        <Color x:Key="Bg3Color">#222222</Color>
        <Color x:Key="AccColor">#E8FF47</Color>
        <Color x:Key="Acc2Color">#C8E020</Color>
        <Color x:Key="FgColor">#FFFFFF</Color>
        <Color x:Key="Fg1Color">#999999</Color>
        <Color x:Key="Fg2Color">#555555</Color>
        <Color x:Key="LineColor">#1F1F1F</Color>
        <Color x:Key="GreenColor">#47FF8A</Color>
        <Color x:Key="RedColor">#FF5555</Color>
        <Color x:Key="AmberColor">#FFB347</Color>
        <Color x:Key="BlueColor">#47B8FF</Color>

        <SolidColorBrush x:Key="BgBrush"   Color="{StaticResource BgColor}"/>
        <SolidColorBrush x:Key="Bg1Brush"  Color="{StaticResource Bg1Color}"/>
        <SolidColorBrush x:Key="Bg2Brush"  Color="{StaticResource Bg2Color}"/>
        <SolidColorBrush x:Key="Bg3Brush"  Color="{StaticResource Bg3Color}"/>
        <SolidColorBrush x:Key="AccBrush"  Color="{StaticResource AccColor}"/>
        <SolidColorBrush x:Key="FgBrush"   Color="{StaticResource FgColor}"/>
        <SolidColorBrush x:Key="Fg1Brush"  Color="{StaticResource Fg1Color}"/>
        <SolidColorBrush x:Key="Fg2Brush"  Color="{StaticResource Fg2Color}"/>
        <SolidColorBrush x:Key="LineBrush" Color="{StaticResource LineColor}"/>
        <SolidColorBrush x:Key="GreenBrush" Color="{StaticResource GreenColor}"/>
        <SolidColorBrush x:Key="RedBrush"   Color="{StaticResource RedColor}"/>
        <SolidColorBrush x:Key="AmberBrush" Color="{StaticResource AmberColor}"/>
        <SolidColorBrush x:Key="BlueBrush"  Color="{StaticResource BlueColor}"/>

        <!-- SCROLLBAR -->
        <Style x:Key="ThinScrollBar" TargetType="ScrollBar">
            <Setter Property="Width" Value="4"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.LineUpCommand" Opacity="0" Height="0"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Rectangle RadiusX="2" RadiusY="2" Fill="#333333"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.LineDownCommand" Opacity="0" Height="0"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollViewer">
            <Setter Property="VerticalScrollBarVisibility" Value="Auto"/>
            <Setter Property="HorizontalScrollBarVisibility" Value="Disabled"/>
        </Style>
        <Style TargetType="ScrollBar" BasedOn="{StaticResource ThinScrollBar}"/>

        <!-- CHECKBOX -->
        <Style x:Key="GuiportCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource Fg1Brush}"/>
            <Setter Property="Background" Value="{StaticResource Bg2Brush}"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Padding" Value="6,0,0,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid Background="Transparent">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Border x:Name="box" Width="15" Height="15" CornerRadius="3"
                                    Background="{StaticResource Bg3Brush}"
                                    BorderBrush="#333" BorderThickness="1.5"
                                    VerticalAlignment="Center">
                                <TextBlock x:Name="chk" Text="✓" FontSize="10" FontWeight="Bold"
                                           HorizontalAlignment="Center" VerticalAlignment="Center"
                                           Foreground="#000" Visibility="Collapsed"/>
                            </Border>
                            <ContentPresenter Grid.Column="1" Margin="{TemplateBinding Padding}"
                                              VerticalAlignment="{TemplateBinding VerticalContentAlignment}"
                                              RecognizesAccessKey="True"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="box" Property="Background" Value="{StaticResource AccBrush}"/>
                                <Setter TargetName="box" Property="BorderBrush" Value="{StaticResource AccBrush}"/>
                                <Setter TargetName="chk" Property="Visibility" Value="Visible"/>
                                <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="box" Property="BorderBrush" Value="#555"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- BUTTON BASE -->
        <Style x:Key="GuiportBtn" TargetType="Button">
            <Setter Property="Foreground" Value="{StaticResource Fg1Brush}"/>
            <Setter Property="Background" Value="{StaticResource Bg2Brush}"/>
            <Setter Property="BorderBrush" Value="#2A2A2A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,7"/>
            <Setter Property="FontFamily" Value="Segoe UI Semibold"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#252525"/>
                                <Setter Property="BorderBrush" Value="#3A3A3A"/>
                                <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#1E1E1E"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ACCENT BUTTON -->
        <Style x:Key="AccentBtn" TargetType="Button" BasedOn="{StaticResource GuiportBtn}">
            <Setter Property="Background" Value="#E8FF47"/>
            <Setter Property="BorderBrush" Value="#E8FF47"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="FontFamily" Value="Segoe UI Bold"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#D4EB30"/>
                    <Setter Property="BorderBrush" Value="#D4EB30"/>
                    <Setter Property="Foreground" Value="#000000"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#BFDA20"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- DANGER BUTTON -->
        <Style x:Key="DangerBtn" TargetType="Button" BasedOn="{StaticResource GuiportBtn}">
            <Setter Property="Background" Value="#1A0A0A"/>
            <Setter Property="BorderBrush" Value="#3A1515"/>
            <Setter Property="Foreground" Value="#FF5555"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#250E0E"/>
                    <Setter Property="BorderBrush" Value="#4A2020"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- NAV BUTTON -->
        <Style x:Key="NavBtn" TargetType="RadioButton">
            <Setter Property="Foreground" Value="{StaticResource Fg1Brush}"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="FontFamily" Value="Segoe UI Semibold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border x:Name="bdr" Background="Transparent"
                                BorderThickness="2,0,0,0" BorderBrush="Transparent"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bdr" Property="Background" Value="#181818"/>
                                <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="bdr" Property="Background" Value="#0F1A00"/>
                                <Setter TargetName="bdr" Property="BorderBrush" Value="{StaticResource AccBrush}"/>
                                <Setter Property="Foreground" Value="{StaticResource AccBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- TEXTBOX -->
        <Style x:Key="GuiportTextBox" TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource Bg2Brush}"/>
            <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
            <Setter Property="BorderBrush" Value="#2A2A2A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontFamily" Value="Cascadia Mono, Consolas"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="CaretBrush" Value="{StaticResource AccBrush}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter Property="BorderBrush" Value="{StaticResource AccBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- SEPARATOR -->
        <Style TargetType="Separator">
            <Setter Property="Background" Value="#1F1F1F"/>
            <Setter Property="Height" Value="1"/>
            <Setter Property="Margin" Value="0"/>
        </Style>

        <!-- TOOLTIP -->
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="#1A1A1A"/>
            <Setter Property="Foreground" Value="#CCCCCC"/>
            <Setter Property="BorderBrush" Value="#333333"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="MaxWidth" Value="300"/>
            <Setter Property="Padding" Value="8,5"/>
        </Style>
    </Window.Resources>

    <!-- ROOT -->
    <Border Background="{StaticResource BgBrush}" CornerRadius="12"
            BorderBrush="#1F1F1F" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>   <!-- Titlebar -->
                <RowDefinition Height="*"/>    <!-- Content -->
                <RowDefinition Height="130"/>  <!-- Console -->
            </Grid.RowDefinitions>

            <!-- ═══ TITLEBAR ═══════════════════════════════════════════════ -->
            <Border Grid.Row="0" Background="{StaticResource Bg1Brush}"
                    CornerRadius="12,12,0,0"
                    BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,0,1"
                    MouseLeftButtonDown="TitleBar_MouseDown">
                <Grid Margin="14,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <TextBlock Grid.Column="0" Text="GUIPORT"
                               FontFamily="Segoe UI Black" FontSize="14"
                               Foreground="{StaticResource AccBrush}"
                               VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <TextBlock Grid.Column="1" Text="PC OPTIMIZER"
                               FontFamily="Cascadia Mono, Consolas" FontSize="9"
                               Foreground="{StaticResource Fg2Brush}"
                               VerticalAlignment="Center" Margin="0,0,0,0"/>

                    <TextBlock Grid.Column="3" x:Name="StatusText"
                               Text="● ONLINE" FontFamily="Cascadia Mono, Consolas" FontSize="9"
                               Foreground="{StaticResource GreenBrush}"
                               VerticalAlignment="Center" Margin="0,0,12,0"/>
                    <TextBlock Grid.Column="4" x:Name="ClockText"
                               Text="00:00:00" FontFamily="Cascadia Mono, Consolas" FontSize="9"
                               Foreground="{StaticResource Fg2Brush}"
                               VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <Button Grid.Column="4" x:Name="CloseBtn"
                            Content="✕" Width="28" Height="28"
                            FontSize="11" Cursor="Hand"
                            Background="Transparent" BorderThickness="0"
                            Foreground="{StaticResource Fg2Brush}"
                            Margin="50,0,0,0" VerticalAlignment="Center">
                        <Button.Style>
                            <Style TargetType="Button">
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="Button">
                                            <Border x:Name="b" Background="Transparent" CornerRadius="4"
                                                    Width="28" Height="28">
                                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            </Border>
                                            <ControlTemplate.Triggers>
                                                <Trigger Property="IsMouseOver" Value="True">
                                                    <Setter TargetName="b" Property="Background" Value="#FF333333"/>
                                                    <Setter Property="Foreground" Value="#FF5555"/>
                                                </Trigger>
                                            </ControlTemplate.Triggers>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </Button.Style>
                    </Button>
                </Grid>
            </Border>

            <!-- ═══ MAIN CONTENT ════════════════════════════════════════════ -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="190"/>  <!-- Sidebar -->
                    <ColumnDefinition Width="*"/>    <!-- Pages -->
                </Grid.ColumnDefinitions>

                <!-- SIDEBAR -->
                <Border Grid.Column="0" Background="{StaticResource Bg1Brush}"
                        BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,1,0">
                    <DockPanel>
                        <StackPanel DockPanel.Dock="Bottom" Margin="14,0,14,14">
                            <Separator Margin="0,0,0,10"/>
                            <!-- CPU bar -->
                            <Grid Margin="0,0,0,5">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="30"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="32"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="CPU" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                                <Border Grid.Column="1" Height="2" Background="#222" CornerRadius="1" Margin="4,0">
                                    <Border x:Name="CpuBar" HorizontalAlignment="Left" Width="0" Background="{StaticResource AccBrush}" CornerRadius="1"/>
                                </Border>
                                <TextBlock x:Name="CpuPct" Grid.Column="2" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource AccBrush}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            </Grid>
                            <!-- RAM bar -->
                            <Grid Margin="0,0,0,5">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="30"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="32"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="RAM" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                                <Border Grid.Column="1" Height="2" Background="#222" CornerRadius="1" Margin="4,0">
                                    <Border x:Name="RamBar" HorizontalAlignment="Left" Width="0" Background="{StaticResource BlueBrush}" CornerRadius="1"/>
                                </Border>
                                <TextBlock x:Name="RamPct" Grid.Column="2" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource BlueBrush}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            </Grid>
                            <!-- DISK bar -->
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="30"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="32"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="DSK" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                                <Border Grid.Column="1" Height="2" Background="#222" CornerRadius="1" Margin="4,0">
                                    <Border x:Name="DskBar" HorizontalAlignment="Left" Width="0" Background="{StaticResource GreenBrush}" CornerRadius="1"/>
                                </Border>
                                <TextBlock x:Name="DskPct" Grid.Column="2" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource GreenBrush}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            </Grid>
                        </StackPanel>

                        <StackPanel Margin="0,8,0,0">
                            <TextBlock Text="MENU" FontFamily="Cascadia Mono, Consolas" FontSize="8"
                                       Foreground="{StaticResource Fg2Brush}" Margin="16,8,0,4"
                                       LetterSpacing="2"/>
                            <RadioButton x:Name="NavInstall" Content="  ⊕  Instalar" Style="{StaticResource NavBtn}" GroupName="nav" IsChecked="True"/>
                            <RadioButton x:Name="NavTweaks"  Content="  ⚡  Tweaks"   Style="{StaticResource NavBtn}" GroupName="nav"/>
                            <RadioButton x:Name="NavConfig"  Content="  ◎  Definições" Style="{StaticResource NavBtn}" GroupName="nav"/>

                            <TextBlock Text="SISTEMA" FontFamily="Cascadia Mono, Consolas" FontSize="8"
                                       Foreground="{StaticResource Fg2Brush}" Margin="16,14,0,4"
                                       LetterSpacing="2"/>
                            <RadioButton x:Name="NavInfo"    Content="  ◷  Hardware"  Style="{StaticResource NavBtn}" GroupName="nav"/>
                        </StackPanel>
                    </DockPanel>
                </Border>

                <!-- PAGES -->
                <Grid Grid.Column="1">

                    <!-- ── PAGE: INSTALL ── -->
                    <Grid x:Name="PageInstall" Visibility="Visible">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="48"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="34"/>
                        </Grid.RowDefinitions>

                        <!-- Topbar -->
                        <Border Grid.Row="0" BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,0,1">
                            <Grid Margin="18,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="Instalar Software" FontFamily="Segoe UI Bold" FontSize="13" Foreground="{StaticResource FgBrush}" VerticalAlignment="Center"/>
                                <TextBlock Grid.Column="1" Text="  // via winget" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                                <TextBox   Grid.Column="2" x:Name="SearchBox" Style="{StaticResource GuiportTextBox}"
                                           Height="26" Margin="20,0,12,0" VerticalAlignment="Center"
                                           ToolTip="Pesquisar aplicações..."/>
                                <Button Grid.Column="3" x:Name="BtnDeselectAll" Content="✕ Limpar" Style="{StaticResource GuiportBtn}" Margin="0,0,5,0" Height="26"/>
                                <Button Grid.Column="4" x:Name="BtnSelectAll"   Content="☑ Todos"  Style="{StaticResource GuiportBtn}" Margin="0,0,5,0" Height="26"/>
                                <Button Grid.Column="5" x:Name="BtnInstall"     Content="▶  Instalar Selecionados" Style="{StaticResource AccentBtn}" Height="28"/>
                            </Grid>
                        </Border>

                        <!-- App List -->
                        <ScrollViewer Grid.Row="1" x:Name="AppScrollViewer">
                            <StackPanel x:Name="AppPanel" Margin="16,10"/>
                        </ScrollViewer>

                        <!-- Selbar -->
                        <Border Grid.Row="2" Background="{StaticResource Bg1Brush}"
                                BorderBrush="{StaticResource LineBrush}" BorderThickness="0,1,0,0">
                            <Grid Margin="18,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock x:Name="SelCount" Text="0 packages selecionados"
                                           FontFamily="Cascadia Mono, Consolas" FontSize="10"
                                           Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                                <TextBlock Grid.Column="1" Text="Instala silenciosamente via winget"
                                           FontFamily="Cascadia Mono, Consolas" FontSize="10"
                                           Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                    </Grid>

                    <!-- ── PAGE: TWEAKS ── -->
                    <Grid x:Name="PageTweaks" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="48"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <Border Grid.Row="0" BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,0,1">
                            <Grid Margin="18,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="Windows Tweaks" FontFamily="Segoe UI Bold" FontSize="13" Foreground="{StaticResource FgBrush}" VerticalAlignment="Center"/>
                                <TextBlock Grid.Column="1" Text="  // performance, privacidade, UI" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                                <Button Grid.Column="3" x:Name="BtnUndoTweaks"  Content="↩ Reverter"       Style="{StaticResource DangerBtn}" Height="26" Margin="0,0,6,0"/>
                                <Button Grid.Column="4" x:Name="BtnApplyTweaks" Content="⚡  Aplicar Tweaks" Style="{StaticResource AccentBtn}" Height="28"/>
                            </Grid>
                        </Border>

                        <ScrollViewer Grid.Row="1">
                            <StackPanel x:Name="TweakPanel" Margin="16,10"/>
                        </ScrollViewer>
                    </Grid>

                    <!-- ── PAGE: CONFIG ── -->
                    <Grid x:Name="PageConfig" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="48"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Border Grid.Row="0" BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,0,1">
                            <TextBlock Text="Definições" FontFamily="Segoe UI Bold" FontSize="13" Foreground="{StaticResource FgBrush}" VerticalAlignment="Center" Margin="18,0"/>
                        </Border>
                        <ScrollViewer Grid.Row="1">
                            <StackPanel Margin="18,14" MaxWidth="560">
                                <TextBlock Text="SOBRE O GUIPORT" FontFamily="Cascadia Mono, Consolas" FontSize="9"
                                           Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,10"/>
                                <Border Background="{StaticResource Bg1Brush}" BorderBrush="{StaticResource LineBrush}"
                                        BorderThickness="1" CornerRadius="6" Padding="16">
                                    <StackPanel>
                                        <TextBlock Text="GUIPORT v1.0" FontFamily="Segoe UI Black" FontSize="18"
                                                   Foreground="{StaticResource AccBrush}" Margin="0,0,0,8"/>
                                        <TextBlock FontFamily="Cascadia Mono, Consolas" FontSize="10" Foreground="{StaticResource Fg1Brush}" TextWrapping="Wrap" LineHeight="20">
                                            <Run Text="Arquitetura:   "/>
                                            <Run Text="PowerShell WPF/XAML nativo" Foreground="White"/>
                                            <LineBreak/>
                                            <Run Text="Inspirado em:  "/>
                                            <Run Text="WinUtil de Chris Titus Tech" Foreground="White"/>
                                            <LineBreak/>
                                            <Run Text="Execucao:      "/>
                                            <Run Text="irm guiport.ps1 | iex" Foreground="{StaticResource AccBrush}"/>
                                            <LineBreak/>
                                            <LineBreak/>
                                            <Run Text="Executa sempre como Administrador para funcionalidade completa." Foreground="#555"/>
                                        </TextBlock>
                                    </StackPanel>
                                </Border>

                                <TextBlock Text="ACOES RAPIDAS" FontFamily="Cascadia Mono, Consolas" FontSize="9"
                                           Foreground="{StaticResource Fg2Brush}" Margin="0,20,0,10"/>
                                <UniformGrid Columns="2" Margin="0,0,0,0">
                                    <Button x:Name="BtnFlushDns"   Content="Flush DNS Cache"         Style="{StaticResource GuiportBtn}" Margin="0,0,5,5" Height="30"/>
                                    <Button x:Name="BtnClearTemp"  Content="Limpar Temp Files"        Style="{StaticResource GuiportBtn}" Margin="0,0,0,5" Height="30"/>
                                    <Button x:Name="BtnSfc"        Content="System File Checker"      Style="{StaticResource GuiportBtn}" Margin="0,0,5,5" Height="30"/>
                                    <Button x:Name="BtnChkDsk"     Content="Check Disk (C:)"          Style="{StaticResource GuiportBtn}" Margin="0,0,0,5" Height="30"/>
                                    <Button x:Name="BtnWinUpdate"  Content="Verificar Atualizacoes"   Style="{StaticResource GuiportBtn}" Margin="0,0,5,5" Height="30"/>
                                    <Button x:Name="BtnScan"       Content="Scan Completo do Sistema" Style="{StaticResource AccentBtn}"  Margin="0,0,0,5" Height="30"/>
                                </UniformGrid>
                            </StackPanel>
                        </ScrollViewer>
                    </Grid>

                    <!-- ── PAGE: INFO ── -->
                    <Grid x:Name="PageInfo" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="48"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Border Grid.Row="0" BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,0,1">
                            <Grid Margin="18,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Hardware do Sistema" FontFamily="Segoe UI Bold" FontSize="13" Foreground="{StaticResource FgBrush}" VerticalAlignment="Center"/>
                                <Button Grid.Column="1" x:Name="BtnRefreshInfo" Content="↻ Atualizar" Style="{StaticResource GuiportBtn}" Height="26"/>
                            </Grid>
                        </Border>
                        <ScrollViewer Grid.Row="1">
                            <UniformGrid Columns="2" Margin="16,12">
                                <!-- OS -->
                                <Border Margin="0,0,5,5" Background="{StaticResource Bg1Brush}"
                                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                                    <StackPanel>
                                        <TextBlock Text="SISTEMA OPERATIVO" FontFamily="Cascadia Mono, Consolas" FontSize="8" Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,5"/>
                                        <TextBlock x:Name="InfoOS" Text="—" FontFamily="Segoe UI Bold" FontSize="12" Foreground="{StaticResource FgBrush}" TextWrapping="Wrap"/>
                                        <TextBlock x:Name="InfoOSSub" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" Margin="0,3,0,0"/>
                                    </StackPanel>
                                </Border>
                                <!-- CPU -->
                                <Border Margin="0,0,0,5" Background="{StaticResource Bg1Brush}"
                                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                                    <StackPanel>
                                        <TextBlock Text="CPU" FontFamily="Cascadia Mono, Consolas" FontSize="8" Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,5"/>
                                        <TextBlock x:Name="InfoCPU" Text="—" FontFamily="Segoe UI Bold" FontSize="12" Foreground="{StaticResource FgBrush}" TextWrapping="Wrap"/>
                                        <TextBlock x:Name="InfoCPUSub" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" Margin="0,3,0,0"/>
                                    </StackPanel>
                                </Border>
                                <!-- RAM -->
                                <Border Margin="0,0,5,5" Background="{StaticResource Bg1Brush}"
                                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                                    <StackPanel>
                                        <TextBlock Text="MEMORIA RAM" FontFamily="Cascadia Mono, Consolas" FontSize="8" Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,5"/>
                                        <TextBlock x:Name="InfoRAM" Text="—" FontFamily="Segoe UI Bold" FontSize="12" Foreground="{StaticResource FgBrush}"/>
                                        <TextBlock x:Name="InfoRAMSub" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" Margin="0,3,0,0"/>
                                    </StackPanel>
                                </Border>
                                <!-- GPU -->
                                <Border Margin="0,0,0,5" Background="{StaticResource Bg1Brush}"
                                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                                    <StackPanel>
                                        <TextBlock Text="GPU" FontFamily="Cascadia Mono, Consolas" FontSize="8" Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,5"/>
                                        <TextBlock x:Name="InfoGPU" Text="—" FontFamily="Segoe UI Bold" FontSize="12" Foreground="{StaticResource FgBrush}" TextWrapping="Wrap"/>
                                        <TextBlock x:Name="InfoGPUSub" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" Margin="0,3,0,0"/>
                                    </StackPanel>
                                </Border>
                                <!-- DISK -->
                                <Border Margin="0,0,5,5" Background="{StaticResource Bg1Brush}"
                                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                                    <StackPanel>
                                        <TextBlock Text="DISCO C:" FontFamily="Cascadia Mono, Consolas" FontSize="8" Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,5"/>
                                        <TextBlock x:Name="InfoDisk" Text="—" FontFamily="Segoe UI Bold" FontSize="12" Foreground="{StaticResource FgBrush}"/>
                                        <TextBlock x:Name="InfoDiskSub" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" Margin="0,3,0,0"/>
                                    </StackPanel>
                                </Border>
                                <!-- SECURITY -->
                                <Border Margin="0,0,0,5" Background="{StaticResource Bg1Brush}"
                                        BorderBrush="{StaticResource LineBrush}" BorderThickness="1" CornerRadius="6" Padding="12">
                                    <StackPanel>
                                        <TextBlock Text="SEGURANCA" FontFamily="Cascadia Mono, Consolas" FontSize="8" Foreground="{StaticResource Fg2Brush}" Margin="0,0,0,5"/>
                                        <TextBlock x:Name="InfoDef" Text="—" FontFamily="Segoe UI Bold" FontSize="12" Foreground="{StaticResource FgBrush}"/>
                                        <TextBlock x:Name="InfoWinget" Text="—" FontFamily="Cascadia Mono, Consolas" FontSize="9" Foreground="{StaticResource Fg2Brush}" Margin="0,3,0,0"/>
                                    </StackPanel>
                                </Border>
                            </UniformGrid>
                        </ScrollViewer>
                    </Grid>

                </Grid>
            </Grid>

            <!-- ═══ CONSOLE ════════════════════════════════════════════════ -->
            <Border Grid.Row="2" Background="{StaticResource BgBrush}"
                    BorderBrush="{StaticResource LineBrush}" BorderThickness="0,1,0,0"
                    CornerRadius="0,0,12,12">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="24"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <!-- Console header -->
                    <Border Grid.Row="0" Background="{StaticResource Bg1Brush}"
                            BorderBrush="{StaticResource LineBrush}" BorderThickness="0,0,0,1">
                        <Grid Margin="12,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Ellipse Width="6" Height="6" Fill="{StaticResource GreenBrush}" VerticalAlignment="Center" Margin="0,0,6,0" x:Name="ConDot"/>
                            <TextBlock Grid.Column="1" Text="CONSOLE" FontFamily="Cascadia Mono, Consolas" FontSize="9"
                                       Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <TextBlock Grid.Column="2" x:Name="ConStatus" Text="A iniciar..."
                                       FontFamily="Cascadia Mono, Consolas" FontSize="9"
                                       Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center"/>
                            <TextBlock Grid.Column="3" x:Name="ConLines" Text="0 linhas"
                                       FontFamily="Cascadia Mono, Consolas" FontSize="9"
                                       Foreground="{StaticResource Fg2Brush}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <Button Grid.Column="4" x:Name="BtnClearCon" Content="limpar"
                                    FontFamily="Cascadia Mono, Consolas" FontSize="9"
                                    Background="{StaticResource Bg2Brush}"
                                    BorderBrush="{StaticResource LineBrush}" BorderThickness="1"
                                    Foreground="{StaticResource Fg2Brush}"
                                    Padding="7,2" Cursor="Hand" Height="18"
                                    VerticalAlignment="Center">
                                <Button.Template>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}"
                                                BorderBrush="{TemplateBinding BorderBrush}"
                                                BorderThickness="{TemplateBinding BorderThickness}"
                                                CornerRadius="3" Padding="{TemplateBinding Padding}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter Property="Foreground" Value="{StaticResource FgBrush}"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </Button.Template>
                            </Button>
                        </Grid>
                    </Border>

                    <!-- Console output -->
                    <ScrollViewer Grid.Row="1" x:Name="ConScroll" Padding="0">
                        <TextBlock x:Name="ConOut"
                                   FontFamily="Cascadia Mono, Consolas" FontSize="10"
                                   Foreground="{StaticResource Fg2Brush}"
                                   Padding="12,4" TextWrapping="Wrap"
                                   LineHeight="18"/>
                    </ScrollViewer>
                </Grid>
            </Border>

        </Grid>
    </Border>
</Window>
'@

# ─── Parse XAML ───────────────────────────────────────────────────────────────
$xaml = $xaml -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[xml]$xml = $xaml
$reader   = New-Object System.Xml.XmlNodeReader $xml
try {
    $sync.Form = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "Erro ao carregar XAML: $_" -ForegroundColor Red
    exit 1
}

# ─── Bind todos os controlos ──────────────────────────────────────────────────
$xml.SelectNodes("//*[@Name]") | ForEach-Object {
    $sync[$_.Name] = $sync.Form.FindName($_.Name)
}

# ─── Dados: Apps ──────────────────────────────────────────────────────────────
$Apps = @(
    # Browsers
    @{ Cat="🌐 Browsers";      Name="Google Chrome";      Pkg="Google.Chrome";                    Desc="Browser mais usado. Motor V8, sync Google, vasto ecossistema." }
    @{ Cat="🌐 Browsers";      Name="Mozilla Firefox";     Pkg="Mozilla.Firefox";                  Desc="Open-source, focado em privacidade. Melhores DevTools da categoria." }
    @{ Cat="🌐 Browsers";      Name="Brave";               Pkg="Brave.Brave";                      Desc="Chromium com bloqueio nativo de anúncios e fingerprint protection." }
    @{ Cat="🌐 Browsers";      Name="Zen Browser";         Pkg="Zen-Team.Zen-Browser";             Desc="Firefox com UI minimalista, abas verticais e foco em produtividade." }
    @{ Cat="🌐 Browsers";      Name="Vivaldi";             Pkg="Vivaldi.Vivaldi";                  Desc="Chromium configurável com tab stacking e cliente de mail integrado." }
    # Comunicação
    @{ Cat="💬 Comunicação";   Name="Discord";             Pkg="Discord.Discord";                  Desc="Plataforma de voz, vídeo e texto para comunidades e gaming." }
    @{ Cat="💬 Comunicação";   Name="Slack";               Pkg="SlackTechnologies.Slack";          Desc="Mensagens para equipas com canais, threads e integrações." }
    @{ Cat="💬 Comunicação";   Name="Telegram";            Pkg="Telegram.TelegramDesktop";         Desc="Mensagens encriptadas com sync na cloud e grupos grandes." }
    @{ Cat="💬 Comunicação";   Name="WhatsApp";            Pkg="WhatsApp.WhatsApp";                Desc="Cliente desktop com encriptação end-to-end. Espelha o telemóvel." }
    # Gaming
    @{ Cat="🎮 Gaming";        Name="Steam";               Pkg="Valve.Steam";                      Desc="A maior loja de jogos PC. Cloud saves, workshop, remote play." }
    @{ Cat="🎮 Gaming";        Name="Epic Games Launcher"; Pkg="EpicGames.EpicGamesLauncher";      Desc="Launcher Epic com jogos gratuitos regulares." }
    @{ Cat="🎮 Gaming";        Name="Ubisoft Connect";     Pkg="Ubisoft.Connect";                  Desc="Hub Ubisoft para gerir biblioteca e conquistas." }
    @{ Cat="🎮 Gaming";        Name="EA App";              Pkg="ElectronicArts.EADesktop";         Desc="App EA para FIFA, The Sims, Battlefield e outros." }
    @{ Cat="🎮 Gaming";        Name="GeForce Experience";  Pkg="Nvidia.GeForceExperience";         Desc="NVIDIA: drivers, otimização de jogos, ShadowPlay, Ansel." }
    @{ Cat="🎮 Gaming";        Name="Playnite";            Pkg="Playnite.Playnite";                Desc="Gestor open-source de jogos. Unifica Steam, Epic, GOG, Xbox." }
    # Utilitários
    @{ Cat="🔧 Utilitários";   Name="7-Zip";               Pkg="7zip.7zip";                        Desc="Compressor open-source. 7z, ZIP, RAR. Melhor taxa de compressão." }
    @{ Cat="🔧 Utilitários";   Name="Notepad++";           Pkg="Notepad++.Notepad++";              Desc="Editor leve com syntax highlighting para 80+ linguagens." }
    @{ Cat="🔧 Utilitários";   Name="VLC";                 Pkg="VLC.VLC";                          Desc="Player multimédia. Reproduz qualquer formato sem codecs extras." }
    @{ Cat="🔧 Utilitários";   Name="ShareX";              Pkg="ShareX.ShareX";                    Desc="Captura de ecrã e gravação gratuita com editor e upload cloud." }
    @{ Cat="🔧 Utilitários";   Name="Bitwarden";           Pkg="Bitwarden.Bitwarden";              Desc="Gestor de passwords open-source com encriptação end-to-end." }
    @{ Cat="🔧 Utilitários";   Name="Rufus";               Pkg="Rufus.Rufus";                      Desc="Cria drives USB bootáveis a partir de ISOs. Suporte UEFI." }
    @{ Cat="🔧 Utilitários";   Name="CrystalDiskInfo";     Pkg="CrystalDewWorld.CrystalDiskInfo";  Desc="Monitoriza SMART de HDD/SSD: saúde, temperatura, avisos." }
    @{ Cat="🔧 Utilitários";   Name="EarTrumpet";          Pkg="File-New-Project.EarTrumpet";      Desc="Mixer de volume avançado por aplicação na system tray." }
    # Desenvolvimento
    @{ Cat="💻 Desenvolvimento"; Name="VS Code";           Pkg="Microsoft.VisualStudioCode";       Desc="Editor Microsoft com IntelliSense, debug, Git e extensões." }
    @{ Cat="💻 Desenvolvimento"; Name="Git";               Pkg="Git.Git";                          Desc="Controlo de versões distribuído. Essencial para qualquer dev." }
    @{ Cat="💻 Desenvolvimento"; Name="Node.js LTS";       Pkg="OpenJS.NodeJS.LTS";                Desc="Runtime JavaScript V8. Necessário para npm e frameworks JS." }
    @{ Cat="💻 Desenvolvimento"; Name="Python 3";          Pkg="Python.Python.3";                  Desc="Linguagem para scripting, data science, IA/ML e backends." }
    @{ Cat="💻 Desenvolvimento"; Name="Windows Terminal";  Pkg="Microsoft.WindowsTerminal";        Desc="Terminal moderno com multi-tab, split panes e GPU rendering." }
    @{ Cat="💻 Desenvolvimento"; Name="Docker Desktop";    Pkg="Docker.DockerDesktop";             Desc="Containerização para build, ship e run de apps isoladas." }
    @{ Cat="💻 Desenvolvimento"; Name="Postman";           Pkg="Postman.Postman";                  Desc="Desenvolvimento e teste de APIs REST e GraphQL." }
    # Media
    @{ Cat="🎨 Media & Criativo"; Name="OBS Studio";       Pkg="OBSProject.OBSStudio";             Desc="Streaming e gravação open-source. Múltiplas cenas e fontes." }
    @{ Cat="🎨 Media & Criativo"; Name="Spotify";          Pkg="Spotify.Spotify";                  Desc="Streaming de música e podcasts com 100M+ faixas." }
    @{ Cat="🎨 Media & Criativo"; Name="Figma";            Pkg="Figma.Figma";                      Desc="Design UI/UX colaborativo. Vetorial, prototipagem, componentes." }
    @{ Cat="🎨 Media & Criativo"; Name="HandBrake";        Pkg="HandBrake.HandBrake";              Desc="Transcodificador de vídeo H.264/H.265/AV1 GPU-acelerado." }
    @{ Cat="🎨 Media & Criativo"; Name="GIMP";             Pkg="GIMP.GIMP";                        Desc="Editor de imagem open-source. Alternativa gratuita ao Photoshop." }
)

# ─── Dados: Tweaks ────────────────────────────────────────────────────────────
$Tweaks = @(
    # Performance
    @{ Cat="⚡ Performance"; Name="High Performance Power Plan"; Desc="Maximiza frequência CPU/GPU — desativa poupança de energia"
       Registry=@(@{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec";Name="Attributes";Value=0;Type="DWord"})
       Script={ powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c }
       Undo={ powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e } }
    @{ Cat="⚡ Performance"; Name="Desativar Xbox Game Bar & DVR"; Desc="Remove overhead de CPU/RAM da gravação em segundo plano"
       Registry=@(@{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR";Name="AppCaptureEnabled";Value=0;Type="DWord"},
                  @{Path="HKCU:\System\GameConfigStore";Name="GameDVR_Enabled";Value=0;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="⚡ Performance"; Name="Desativar SysMain (Superfetch)"; Desc="Elimina picos desnecessários de disco em sistemas SSD"
       Registry=$null
       Script={ Stop-Service -Name SysMain -Force -EA SilentlyContinue; Set-Service -Name SysMain -StartupType Disabled }
       Undo={ Set-Service -Name SysMain -StartupType Automatic; Start-Service -Name SysMain -EA SilentlyContinue } }
    @{ Cat="⚡ Performance"; Name="Desativar Hibernação"; Desc="Liberta espaço em disco igual à RAM instalada"
       Registry=$null; Script={ powercfg -h off }; Undo={ powercfg -h on } }
    @{ Cat="⚡ Performance"; Name="Ativar Game Mode"; Desc="Prioridade CPU/GPU para jogos — reduz stuttering"
       Registry=@(@{Path="HKCU:\Software\Microsoft\GameBar";Name="AllowAutoGameMode";Value=1;Type="DWord"},
                  @{Path="HKCU:\Software\Microsoft\GameBar";Name="AutoGameModeEnabled";Value=1;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="⚡ Performance"; Name="Desativar Search Indexing"; Desc="Para indexação em segundo plano — reduz I/O em SSDs"
       Registry=$null
       Script={ Stop-Service -Name WSearch -Force -EA SilentlyContinue; Set-Service -Name WSearch -StartupType Disabled }
       Undo={ Set-Service -Name WSearch -StartupType Automatic; Start-Service -Name WSearch -EA SilentlyContinue } }
    # Privacidade
    @{ Cat="🔒 Privacidade"; Name="Desativar Telemetria"; Desc="Bloqueia recolha e envio de dados de diagnóstico"
       Registry=@(@{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection";Name="AllowTelemetry";Value=0;Type="DWord"})
       Script={ Stop-Service DiagTrack -Force -EA SilentlyContinue; Set-Service DiagTrack -StartupType Disabled }
       Undo={ Set-Service DiagTrack -StartupType Automatic } }
    @{ Cat="🔒 Privacidade"; Name="Desativar Advertising ID"; Desc="Remove identificador de rastreamento de anúncios"
       Registry=@(@{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo";Name="Enabled";Value=0;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="🔒 Privacidade"; Name="Desativar Cortana"; Desc="Para pesquisas de serem enviadas para a cloud Microsoft"
       Registry=@(@{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search";Name="AllowCortana";Value=0;Type="DWord"},
                  @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search";Name="BingSearchEnabled";Value=0;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="🔒 Privacidade"; Name="Desativar Activity History"; Desc="Desativa registo de apps/ficheiros abertos e upload cloud"
       Registry=@(@{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";Name="EnableActivityFeed";Value=0;Type="DWord"},
                  @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";Name="PublishUserActivities";Value=0;Type="DWord"},
                  @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";Name="UploadUserActivities";Value=0;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="🔒 Privacidade"; Name="Desativar Location Tracking"; Desc="Bloqueia todas as apps de acederem à tua localização"
       Registry=@(@{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors";Name="DisableLocation";Value=1;Type="DWord"})
       Script=$null; Undo=$null }
    # Interface
    @{ Cat="🖥️ Interface"; Name="Context Menu Clássico (Win10)"; Desc="Restaura menu Win10 — remove 'Mostrar mais opções'"
       Registry=$null
       Script={ reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve 2>&1 | Out-Null; Stop-Process -Name explorer -Force; Start-Process explorer }
       Undo={ reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>&1 | Out-Null; Stop-Process -Name explorer -Force; Start-Process explorer } }
    @{ Cat="🖥️ Interface"; Name="Mostrar Extensões de Ficheiros"; Desc="Mostra .exe .docx .jpg — ocultos por defeito"
       Registry=@(@{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";Name="HideFileExt";Value=0;Type="DWord"})
       Script={ Stop-Process -Name explorer -Force; Start-Process explorer }; Undo=$null }
    @{ Cat="🖥️ Interface"; Name="Mostrar Ficheiros Ocultos"; Desc="Revela ficheiros de sistema e pastas AppData"
       Registry=@(@{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";Name="Hidden";Value=1;Type="DWord"},
                  @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";Name="ShowSuperHidden";Value=1;Type="DWord"})
       Script={ Stop-Process -Name explorer -Force; Start-Process explorer }; Undo=$null }
    @{ Cat="🖥️ Interface"; Name="Ativar Dark Mode Global"; Desc="Aplica tema escuro ao Explorer, Definições e apps"
       Registry=@(@{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize";Name="AppsUseLightTheme";Value=0;Type="DWord"},
                  @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize";Name="SystemUsesLightTheme";Value=0;Type="DWord"})
       Script=$null; Undo=$null }
    # Segurança
    @{ Cat="🛡️ Segurança"; Name="Forçar Defender Real-Time"; Desc="Garante scanning contínuo e proteção cloud ativos"
       Registry=$null
       Script={ Set-MpPreference -DisableRealtimeMonitoring $false; Set-MpPreference -CloudBlockLevel 2 }; Undo=$null }
    @{ Cat="🛡️ Segurança"; Name="UAC — Nível Máximo"; Desc="Bloqueia elevação silenciosa de privilégios por malware"
       Registry=@(@{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System";Name="ConsentPromptBehaviorAdmin";Value=2;Type="DWord"},
                  @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System";Name="PromptOnSecureDesktop";Value=1;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="🛡️ Segurança"; Name="Ativar Controlled Folder Access"; Desc="Proteção anti-ransomware para Documentos e Desktop"
       Registry=$null
       Script={ Set-MpPreference -EnableControlledFolderAccess Enabled }; Undo=$null }
    # Rede
    @{ Cat="🌐 Rede"; Name="Desativar Network Throttling"; Desc="Remove limite de 10% de largura de banda reservada"
       Registry=@(@{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile";Name="NetworkThrottlingIndex";Value=0xffffffff;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="🌐 Rede"; Name="Desativar Delivery Optimization"; Desc="Para envio de atualizações Windows para outros PCs"
       Registry=@(@{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization";Name="DODownloadMode";Value=0;Type="DWord"})
       Script=$null; Undo=$null }
    @{ Cat="🌐 Rede"; Name="DNS Cloudflare 1.1.1.1"; Desc="DNS mais rápido e privado — substitui o padrão do operador"
       Registry=$null
       Script={ $a=Get-NetAdapter|Where-Object{$_.Status -eq 'Up'}|Select-Object -First 1; Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses '1.1.1.1','1.0.0.1' }
       Undo={ $a=Get-NetAdapter|Where-Object{$_.Status -eq 'Up'}|Select-Object -First 1; Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses } }
)

# ─── Constroi UI: Apps ────────────────────────────────────────────────────────
$selectedApps  = [System.Collections.Generic.List[string]]::new()
$allAppChecks  = [System.Collections.Generic.List[System.Windows.Controls.CheckBox]]::new()

$currentCat = ""
$catStack   = $null

function Add-AppSection($cat) {
    $hdr = New-Object System.Windows.Controls.Border
    $hdr.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(26,26,26)))
    $hdr.CornerRadius = [System.Windows.CornerRadius]8
    $hdr.Padding = [System.Windows.Thickness]"12,8,12,8"
    $hdr.Margin = [System.Windows.Thickness]"0,6,0,2"
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $cat
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI Semibold")
    $tb.FontSize = 11
    $tb.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(180,180,180))
    $hdr.Child = $tb
    $sync.AppPanel.Children.Add($hdr) | Out-Null

    $wrap = New-Object System.Windows.Controls.WrapPanel
    $wrap.Margin = [System.Windows.Thickness]"0,2,0,8"
    $sync.AppPanel.Children.Add($wrap) | Out-Null
    return $wrap
}

$Apps | Group-Object Cat | ForEach-Object {
    $wrap = Add-AppSection $_.Name
    foreach ($app in $_.Group) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content    = $app.Name
        $cb.ToolTip    = "$($app.Pkg)`n`n$($app.Desc)"
        $cb.Tag        = $app.Pkg
        $cb.Margin     = [System.Windows.Thickness]"0,1,14,1"
        $cb.MinWidth   = 150
        $cb.Style      = $sync.Form.FindResource("GuiportCheckBox")
        $cb.Add_Checked({
            if (-not $selectedApps.Contains($this.Tag)) { $selectedApps.Add($this.Tag) }
            $sync.SelCount.Text = "$($selectedApps.Count) packages selecionados"
            $sync.Form.FindName("NavInstall").Tag = $selectedApps.Count
        })
        $cb.Add_Unchecked({
            $selectedApps.Remove($this.Tag) | Out-Null
            $sync.SelCount.Text = "$($selectedApps.Count) packages selecionados"
        })
        $wrap.Children.Add($cb) | Out-Null
        $allAppChecks.Add($cb) | Out-Null
    }
}

# ─── Constroi UI: Tweaks ──────────────────────────────────────────────────────
$selectedTweaks = [System.Collections.Generic.List[object]]::new()

$Tweaks | Group-Object Cat | ForEach-Object {
    # Cabeçalho de categoria
    $hdr = New-Object System.Windows.Controls.Border
    $hdr.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(26,26,26)))
    $hdr.CornerRadius = [System.Windows.CornerRadius]8
    $hdr.Padding = [System.Windows.Thickness]"12,8,12,8"
    $hdr.Margin = [System.Windows.Thickness]"0,6,0,2"
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $_.Name
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI Semibold")
    $tb.FontSize = 11
    $tb.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(180,180,180))
    $hdr.Child = $tb
    $sync.TweakPanel.Children.Add($hdr) | Out-Null

    foreach ($tweak in $_.Group) {
        $row = New-Object System.Windows.Controls.Border
        $row.Padding = [System.Windows.Thickness]"10,8,10,8"
        $row.Margin  = [System.Windows.Thickness]"0,1,0,0"
        $row.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(19,19,19)))
        $row.CornerRadius = [System.Windows.CornerRadius]5
        $row.BorderBrush = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(31,31,31)))
        $row.BorderThickness = [System.Windows.Thickness]1

        $grid = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::Auto
        $grid.ColumnDefinitions.Add($c1); $grid.ColumnDefinitions.Add($c2)

        $info = New-Object System.Windows.Controls.StackPanel
        $info.Orientation = "Vertical"
        $nameBlock = New-Object System.Windows.Controls.TextBlock
        $nameBlock.Text = $tweak.Name
        $nameBlock.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI Semibold")
        $nameBlock.FontSize = 12
        $nameBlock.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(220,220,220))
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = $tweak.Desc
        $descBlock.FontFamily = New-Object System.Windows.Media.FontFamily("Cascadia Mono, Consolas")
        $descBlock.FontSize = 9
        $descBlock.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(85,85,85))
        $descBlock.Margin = [System.Windows.Thickness]"0,2,0,0"
        $info.Children.Add($nameBlock) | Out-Null
        $info.Children.Add($descBlock) | Out-Null
        [System.Windows.Controls.Grid]::SetColumn($info, 0)

        # Toggle button
        $tog = New-Object System.Windows.Controls.CheckBox
        $tog.Tag = $tweak
        $tog.VerticalAlignment = "Center"
        $tog.Style = $sync.Form.FindResource("GuiportCheckBox")
        $tog.Content = ""
        [System.Windows.Controls.Grid]::SetColumn($tog, 1)

        $grid.Children.Add($info) | Out-Null
        $grid.Children.Add($tog)  | Out-Null
        $row.Child = $grid
        $sync.TweakPanel.Children.Add($row) | Out-Null
    }
}

# ─── Log helper ───────────────────────────────────────────────────────────────
$logLines = 0
function Write-GuiportLog {
    param([string]$Type, [string]$Message)
    $sync.Form.Dispatcher.Invoke([action]{
        $prefixes = @{ ok='[OK]  '; err='[ERR] '; warn='[WARN]'; info='[INFO]'; dim='      ' }
        $colors   = @{ ok='#47FF8A'; err='#FF5555'; warn='#FFB347'; info='#47B8FF'; dim='#555555' }
        $prefix = $prefixes[$Type]; if (-not $prefix) { $prefix = '[LOG] ' }
        $color  = $colors[$Type];  if (-not $color)  { $color  = '#888888' }

        $run1 = New-Object System.Windows.Documents.Run
        $run1.Text       = $prefix + "  "
        $run1.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString('#333333'))

        $run2 = New-Object System.Windows.Documents.Run
        $run2.Text       = $Message
        $run2.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString($color))

        $sync.ConOut.Inlines.Add($run1)
        $sync.ConOut.Inlines.Add($run2)
        $sync.ConOut.Inlines.Add((New-Object System.Windows.Documents.LineBreak))

        $script:logLines++
        $sync.ConLines.Text = "$script:logLines linhas"
        $sync.ConScroll.ScrollToBottom()
    })
}

function Set-ConStatus {
    param([string]$Text, [string]$Color = "#555555")
    $sync.Form.Dispatcher.Invoke([action]{
        $sync.ConStatus.Text = $Text
        $sync.ConStatus.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString($Color))
    })
}

# ─── Runspace pool ─────────────────────────────────────────────────────────────
$maxthreads = [int]$env:NUMBER_OF_PROCESSORS
$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$hashVar = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync',$sync,$null
$iss.Variables.Add($hashVar)
$sync.runspace = [runspacefactory]::CreateRunspacePool(1, $maxthreads, $iss, $Host)
$sync.runspace.Open()

function Invoke-GuiportRunspace([ScriptBlock]$Script) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $sync.runspace
    [void]$ps.AddScript($Script)
    return $ps.BeginInvoke()
}

# ─── Instalar packages ────────────────────────────────────────────────────────
function Invoke-GuiportInstall {
    if ($selectedApps.Count -eq 0) {
        Write-GuiportLog "warn" "Nenhum package selecionado."
        return
    }
    if ($sync.ProcessRunning) {
        Write-GuiportLog "warn" "Processo ja em execucao. Aguarda..."
        return
    }
    $sync.ProcessRunning = $true
    $pkgs = $selectedApps.ToArray()
    Write-GuiportLog "info" "A instalar $($pkgs.Count) package(s) via winget..."
    Set-ConStatus "A instalar..." "#FFB347"

    Invoke-GuiportRunspace {
        foreach ($pkg in $pkgs) {
            $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "dim" "  winget install --id $pkg" })
            try {
                $out = & winget install --id $pkg -e --silent --accept-package-agreements --accept-source-agreements 2>&1
                $out | ForEach-Object {
                    $l = $_.ToString().Trim()
                    if ($l) { $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "dim" "    $l" }) }
                }
                if ($LASTEXITCODE -eq 0) {
                    $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "ok" "  v $pkg instalado" })
                } else {
                    $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "err" "  Falhou: $pkg (exit $LASTEXITCODE)" })
                }
            } catch {
                $e = $_
                $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "err" "  Excecao: $e" })
            }
        }
        $sync.Form.Dispatcher.Invoke([action]{
            Write-GuiportLog "ok" "Instalacao concluida!"
            Set-ConStatus "Pronto" "#47FF8A"
            $sync.ProcessRunning = $false
        })
    } | Out-Null
}

# ─── Aplicar tweaks ───────────────────────────────────────────────────────────
function Invoke-GuiportTweaks {
    $checked = $sync.TweakPanel.Children | Where-Object {
        $_ -is [System.Windows.Controls.Border]
    } | ForEach-Object {
        $grid = $_.Child
        if ($grid -is [System.Windows.Controls.Grid]) {
            $grid.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.IsChecked }
        }
    }
    if (-not $checked) {
        Write-GuiportLog "warn" "Nenhum tweak selecionado."
        return
    }
    if ($sync.ProcessRunning) { Write-GuiportLog "warn" "Processo ja em execucao."; return }
    $sync.ProcessRunning = $true

    $tweakList = @($checked | ForEach-Object { $_.Tag })
    Write-GuiportLog "info" "A aplicar $($tweakList.Count) tweak(s)..."
    Set-ConStatus "A aplicar tweaks..." "#FFB347"

    Invoke-GuiportRunspace {
        foreach ($tweak in $tweakList) {
            $n = $tweak.Name
            $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "dim" "  Aplicar: $n" })
            try {
                # Registry
                if ($tweak.Registry) {
                    foreach ($reg in $tweak.Registry) {
                        if (-not (Test-Path $reg.Path)) { New-Item -Path $reg.Path -Force | Out-Null }
                        Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type $reg.Type -Force
                    }
                }
                # Script
                if ($tweak.Script) { & $tweak.Script 2>&1 | Out-Null }
                $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "ok" "  v $n" })
            } catch {
                $e = $_
                $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "err" "  $n : $e" })
            }
        }
        $sync.Form.Dispatcher.Invoke([action]{
            Write-GuiportLog "warn" "Alguns tweaks requerem reinicio para ter efeito."
            Write-GuiportLog "ok" "Tweaks aplicados!"
            Set-ConStatus "Pronto" "#47FF8A"
            $sync.ProcessRunning = $false
        })
    } | Out-Null
}

# ─── Reverter tweaks ──────────────────────────────────────────────────────────
function Invoke-GuiportUndoTweaks {
    $sync.TweakPanel.Children | Where-Object { $_ -is [System.Windows.Controls.Border] } | ForEach-Object {
        $grid = $_.Child
        if ($grid -is [System.Windows.Controls.Grid]) {
            $grid.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] } | ForEach-Object {
                $_.IsChecked = $false
            }
        }
    }
    Write-GuiportLog "ok" "Tweaks desmarcados na UI."
}

# ─── Acao rapida ─────────────────────────────────────────────────────────────
function Invoke-QuickAction([string]$Type) {
    if ($sync.ProcessRunning) { Write-GuiportLog "warn" "Processo ja em execucao."; return }
    $sync.ProcessRunning = $true
    $actions = @{
        'FlushDns'   = @{ Label="A limpar cache DNS...";            Script={ ipconfig /flushdns } }
        'ClearTemp'  = @{ Label="A limpar ficheiros temporarios..."; Script={ Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue; Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue } }
        'Sfc'        = @{ Label="A verificar ficheiros do sistema...(demora)"; Script={ sfc /scannow } }
        'ChkDsk'     = @{ Label="A verificar disco C:...";          Script={ chkdsk C: /scan } }
        'WinUpdate'  = @{ Label="A verificar atualizacoes Windows..."; Script={ Get-WindowsUpdate -EA SilentlyContinue | Select-Object Title,Size | Format-Table -AutoSize } }
    }
    $a = $actions[$Type]; if (-not $a) { $sync.ProcessRunning = $false; return }
    Write-GuiportLog "info" $a.Label
    Set-ConStatus "A executar..." "#FFB347"
    $script = $a.Script
    Invoke-GuiportRunspace {
        try {
            $out = & $script 2>&1
            $out | ForEach-Object { $l=$_.ToString().Trim(); if($l){$sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "dim" "  $l" })} }
            $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "ok" "Concluido." })
        } catch {
            $e = $_
            $sync.Form.Dispatcher.Invoke([action]{ Write-GuiportLog "err" "Erro: $e" })
        }
        $sync.Form.Dispatcher.Invoke([action]{ Set-ConStatus "Pronto" "#47FF8A"; $sync.ProcessRunning = $false })
    } | Out-Null
}

# ─── Scan completo ────────────────────────────────────────────────────────────
function Invoke-GuiportScan {
    if ($sync.ProcessRunning) { Write-GuiportLog "warn" "Processo ja em execucao."; return }
    $sync.ProcessRunning = $true
    Write-GuiportLog "info" "A executar scan completo do sistema..."
    Set-ConStatus "A escanear..." "#FFB347"
    Invoke-GuiportRunspace {
        try {
            $os  = Get-CimInstance Win32_OperatingSystem
            $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
            $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
            $cs  = Get-CimInstance Win32_ComputerSystem
            $drv = Get-PSDrive C -EA SilentlyContinue
            $ram    = [math]::Round($cs.TotalPhysicalMemory/1GB, 1)
            $free   = if($drv){[math]::Round($drv.Free/1GB,1)}else{'?'}
            $used   = if($drv){[math]::Round($drv.Used/1GB,1)}else{'?'}
            $winget = $null -ne (Get-Command winget -EA SilentlyContinue)
            $mp     = Get-MpComputerStatus -EA SilentlyContinue
            $def    = ($null -ne $mp) -and $mp.RealTimeProtectionEnabled

            $osStr  = $os.Caption
            $cpuStr = $cpu.Name.Trim()
            $cores  = $cpu.NumberOfCores
            $thr    = $cpu.NumberOfLogicalProcessors
            $gpuStr = $gpu.Name
            $defStr = if($def){"Defender ativo"}else{"Defender DESLIGADO"}
            $wgStr  = if($winget){"Winget disponivel"}else{"Winget nao encontrado"}

            $sync.Form.Dispatcher.Invoke([action]{
                Write-GuiportLog "ok"  "OS:      $osStr"
                Write-GuiportLog "ok"  "CPU:     $cpuStr — $cores cores / $thr threads"
                Write-GuiportLog "ok"  "RAM:     $ram GB"
                Write-GuiportLog "ok"  "GPU:     $gpuStr"
                Write-GuiportLog "ok"  "Disco C: $used GB usado — $free GB livres"
                if($winget){Write-GuiportLog "ok" "Winget:  $wgStr"}else{Write-GuiportLog "warn" "Winget:  $wgStr"}
                if($def){Write-GuiportLog "ok" "Sec:     $defStr"}else{Write-GuiportLog "warn" "Sec:     $defStr"}

                # Atualiza info page
                $sync.InfoOS.Text      = $osStr
                $sync.InfoOSSub.Text   = "Build $($os.BuildNumber) — $($os.OSArchitecture)"
                $sync.InfoCPU.Text     = $cpuStr
                $sync.InfoCPUSub.Text  = "$cores Cores / $thr Threads @ $([math]::Round($cpu.MaxClockSpeed/1000,1)) GHz"
                $sync.InfoRAM.Text     = "$ram GB"
                $sync.InfoRAMSub.Text  = "Total instalada"
                $sync.InfoGPU.Text     = $gpuStr
                $sync.InfoGPUSub.Text  = "Driver $($gpu.DriverVersion)"
                $sync.InfoDisk.Text    = "$used GB usado"
                $sync.InfoDiskSub.Text = "$free GB livres em C:\"
                $sync.InfoDef.Text     = if($def){"✓ Defender Ativo"}else{"✗ Defender Inativo"}
                $sync.InfoDef.Foreground = if($def){New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(71,255,138))}else{New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255,85,85))}
                $sync.InfoWinget.Text  = if($winget){"✓ Winget disponivel"}else{"✗ Winget nao encontrado"}

                Write-GuiportLog "ok" "Scan concluido!"
                Set-ConStatus "Pronto" "#47FF8A"
                $sync.ProcessRunning = $false
            })
        } catch {
            $e = $_
            $sync.Form.Dispatcher.Invoke([action]{
                Write-GuiportLog "err" "Erro no scan: $e"
                Set-ConStatus "Erro" "#FF5555"
                $sync.ProcessRunning = $false
            })
        }
    } | Out-Null
}

# ─── Pesquisa de apps ─────────────────────────────────────────────────────────
function Search-Apps([string]$Query) {
    $q = $Query.ToLower().Trim()
    foreach ($cb in $allAppChecks) {
        $name = $cb.Content.ToString().ToLower()
        $pkg  = $cb.Tag.ToString().ToLower()
        $visible = ($q -eq '') -or $name.Contains($q) -or $pkg.Contains($q)
        $cb.Visibility = if ($visible) { "Visible" } else { "Collapsed" }
    }
}

# ─── Relógio ──────────────────────────────────────────────────────────────────
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
    $sync.ClockText.Text = (Get-Date -Format "HH:mm:ss")
})
$timer.Start()

# ─── Eventos de botões ────────────────────────────────────────────────────────
$sync.CloseBtn.Add_Click({ $sync.Form.Close() })

$sync.Form.Add_MouseLeftButtonDown({
    if (-not ($_.OriginalSource -is [System.Windows.Controls.Button])) {
        $sync.Form.DragMove()
    }
})

# Navegação
$sync.NavInstall.Add_Checked({ $sync.PageInstall.Visibility="Visible"; $sync.PageTweaks.Visibility="Collapsed"; $sync.PageConfig.Visibility="Collapsed"; $sync.PageInfo.Visibility="Collapsed" })
$sync.NavTweaks.Add_Checked({  $sync.PageInstall.Visibility="Collapsed"; $sync.PageTweaks.Visibility="Visible"; $sync.PageConfig.Visibility="Collapsed"; $sync.PageInfo.Visibility="Collapsed" })
$sync.NavConfig.Add_Checked({  $sync.PageInstall.Visibility="Collapsed"; $sync.PageTweaks.Visibility="Collapsed"; $sync.PageConfig.Visibility="Visible"; $sync.PageInfo.Visibility="Collapsed" })
$sync.NavInfo.Add_Checked({    $sync.PageInstall.Visibility="Collapsed"; $sync.PageTweaks.Visibility="Collapsed"; $sync.PageConfig.Visibility="Collapsed"; $sync.PageInfo.Visibility="Visible" })

# Install
$sync.BtnInstall.Add_Click({ Invoke-GuiportInstall })
$sync.BtnSelectAll.Add_Click({ $allAppChecks | ForEach-Object { $_.IsChecked = $true } })
$sync.BtnDeselectAll.Add_Click({ $allAppChecks | ForEach-Object { $_.IsChecked = $false }; $selectedApps.Clear(); $sync.SelCount.Text = "0 packages selecionados" })
$sync.SearchBox.Add_TextChanged({ Search-Apps $sync.SearchBox.Text })

# Tweaks
$sync.BtnApplyTweaks.Add_Click({ Invoke-GuiportTweaks })
$sync.BtnUndoTweaks.Add_Click({ Invoke-GuiportUndoTweaks })

# Quick actions
$sync.BtnFlushDns.Add_Click({  Invoke-QuickAction "FlushDns" })
$sync.BtnClearTemp.Add_Click({ Invoke-QuickAction "ClearTemp" })
$sync.BtnSfc.Add_Click({       Invoke-QuickAction "Sfc" })
$sync.BtnChkDsk.Add_Click({    Invoke-QuickAction "ChkDsk" })
$sync.BtnWinUpdate.Add_Click({ Invoke-QuickAction "WinUpdate" })
$sync.BtnScan.Add_Click({      Invoke-GuiportScan })
$sync.BtnRefreshInfo.Add_Click({ Invoke-GuiportScan })

# Console clear
$sync.BtnClearCon.Add_Click({
    $sync.ConOut.Inlines.Clear()
    $script:logLines = 0
    $sync.ConLines.Text = "0 linhas"
    Write-GuiportLog "info" "Console limpa."
})

# Resize
$sync.Form.Add_Loaded({
    $sync.Form.MinWidth  = 900
    $sync.Form.MinHeight = 580
})
$sync.Form.Add_Closing({
    $timer.Stop()
    $sync.runspace.Close()
    $sync.runspace.Dispose()
    [System.GC]::Collect()
})

# ─── Boot: scan em background ─────────────────────────────────────────────────
Write-GuiportLog "info" "Guiport PC Optimizer a iniciar..."
Write-GuiportLog "dim"  "  Baseado na arquitetura WPF/XAML do WinUtil"
Set-ConStatus "Pronto" "#47FF8A"
$sync.StatusText.Text = "● ONLINE"

Invoke-GuiportRunspace {
    Start-Sleep -Milliseconds 800
    $winget = $null -ne (Get-Command winget -EA SilentlyContinue)
    $mp  = Get-MpComputerStatus -EA SilentlyContinue
    $def = ($null -ne $mp) -and $mp.RealTimeProtectionEnabled
    $sync.Form.Dispatcher.Invoke([action]{
        Write-GuiportLog "ok" "Sistema detetado"
        if($winget){Write-GuiportLog "ok" "  Winget disponivel"}else{Write-GuiportLog "warn" "  Winget nao encontrado"}
        if($def){Write-GuiportLog "ok" "  Defender ativo"}else{Write-GuiportLog "warn" "  Defender desligado"}
        Write-GuiportLog "dim" "  Navega pelo menu lateral para comecar"
    })
} | Out-Null

# ─── Mostrar janela ───────────────────────────────────────────────────────────
$sync.Form.ShowDialog() | Out-Null
Stop-Process -Id $PID
