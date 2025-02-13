#!/bin/bash

set -eufo pipefail

# スマート引用符無効
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# スペースバー2回でピリオド入力無効
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# マウスのスクロール速度
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.75

# Dockを自動的に非表示
defaults write com.apple.dock autohide -bool true

# 最近使ったアプリケーションをDockに表示しない
defaults write com.apple.dock show-recents -bool false

# Dockのアイコンサイズ
defaults write com.apple.dock tilesize -float 46

# Finderでパスバー表示
defaults write com.apple.finder ShowPathbar -bool true

# 音量を常に配置
defaults write com.apple.controlcenter Sound -int 18

# ファストユーザスイッチ非表示
defaults write com.apple.controlcenter UserSwitcher -int 28

# Spotlight非表示
defaults write com.apple.Spotlight MenuItemHidden -bool true

# Siri非表示 TODO: 反映されない
defaults write com.apple.Siri StatusMenuVisible -bool false

# ライブ変換無効
defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

# スクリーンセーバ開始までの時間
defaults -currentHost write com.apple.screensaver idleTime -int 600

# スクリーンセーバに時計を表示
defaults -currentHost write com.apple.screensaver showClock -bool true

# VSCodeのvimキーバインドでキーリピートを有効にする
defaults -currentHost write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# インストールしたフォントを全ユーザで使用可能にする（コンピュータにインストールする）
defaults write com.apple.FontBook FBDefaultInstallDomainRef -int 1

# メニューバーにBluetoothアイコン表示 TODO: 反映されない
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

killall Dock
killall Finder
killall ControlCenter
