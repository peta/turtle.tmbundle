default:
	$(info make icns2imgs:       Converts to ICNS image bundle into multiple separate PNG image files)
	$(info make imgs2icns:       Compile multiple separate PNG image files into a ICNS image bundle)
	$(info make register:        Register file extensions with current TextMate Proxy Runner)
	$(info make unregister:      Unregister current TextMate Proxy Runner for supported file extensions)

icns2imgs:	
	$(info Doing icns2imgs $(ICNS_FILE) )
	iconutil --convert iconset "$(ICNS_FILE)"

imgs2icns:
	$(info Doing imgs2icns $(IMG_DIR) )
	iconutil --convert icns "$(IMG_DIR)"
	
register:
	$(info Registering proxy runner)
	./proxy-installer.sh install
	
unregister:
	$(info Unregistering proxy runner)
	./proxy-installer.sh uninstall