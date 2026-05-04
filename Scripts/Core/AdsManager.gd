extends Node

# AdsManager — autoload singleton.
# Ponte com o SDK do CrazyGames v3 via JavaScriptBridge.
# Em editor (F5) ou fora da web: simula sucesso após 0.6s pra testar a UX
# sem precisar uplodar.
#
# Uso:
#   AdsManager.request_rewarded_ad(
#       func(): print("ad assistido — dar reward"),
#       func(): print("ad pulado/sem fill — sem reward"),
#   )

var _sdk_available: bool = false
var _ad_in_progress: bool = false
var _on_success: Callable = Callable()
var _on_fail: Callable = Callable()

# JavaScriptObject refs precisam ficar vivas para o JS chamar de volta
var _success_cb = null
var _fail_cb = null


func _ready() -> void:
	if not OS.has_feature("web"):
		print("AdsManager: rodando fora da web — modo dev (ads simulados).")
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		print("AdsManager: JavaScriptBridge indisponível.")
		return

	var result = JavaScriptBridge.eval("typeof window.CrazyGames !== 'undefined'", true)
	_sdk_available = (result == true)

	if _sdk_available:
		print("AdsManager: CrazyGames SDK detectado ✓")
		_setup_callbacks()
	else:
		print("AdsManager: SDK do CrazyGames não disponível — usando modo simulado.")


func _setup_callbacks() -> void:
	_success_cb = JavaScriptBridge.create_callback(_on_ad_success_internal)
	_fail_cb = JavaScriptBridge.create_callback(_on_ad_fail_internal)
	var window = JavaScriptBridge.get_interface("window")
	if window != null:
		window.godotAdSuccess = _success_cb
		window.godotAdFail = _fail_cb


func is_real_sdk_available() -> bool:
	return _sdk_available


func is_ad_in_progress() -> bool:
	return _ad_in_progress


# Pede um rewarded ad. Sempre retorna por callback (assíncrono).
# Em editor / sem SDK, simula sucesso após delay.
func request_rewarded_ad(on_success: Callable, on_fail: Callable) -> void:
	if _ad_in_progress:
		on_fail.call()
		return
	_ad_in_progress = true
	_on_success = on_success
	_on_fail = on_fail

	if not _sdk_available:
		# Editor / sem SDK — simula sucesso após meio segundo
		print("AdsManager: simulando rewarded ad bem-sucedido")
		await get_tree().create_timer(0.6).timeout
		_on_ad_success_internal([])
		return

	# Produção — chama o SDK do CrazyGames
	JavaScriptBridge.eval("""
		try {
			window.CrazyGames.SDK.ad.requestAd('rewarded')
				.then(function() { window.godotAdSuccess(); })
				.catch(function() { window.godotAdFail(); });
		} catch(e) {
			window.godotAdFail();
		}
	""", true)


# Notificações de gameplay state pro CrazyGames decidir quando mostrar ads
# institucionais. Chamadas seguras (no-op em editor).
func notify_gameplay_start() -> void:
	if not _sdk_available: return
	JavaScriptBridge.eval("try { window.CrazyGames.SDK.game.gameplayStart(); } catch(e) {}", true)


func notify_gameplay_stop() -> void:
	if not _sdk_available: return
	JavaScriptBridge.eval("try { window.CrazyGames.SDK.game.gameplayStop(); } catch(e) {}", true)


func notify_loading_start() -> void:
	if not _sdk_available: return
	JavaScriptBridge.eval("try { window.CrazyGames.SDK.game.loadingStart(); } catch(e) {}", true)


func notify_loading_stop() -> void:
	if not _sdk_available: return
	JavaScriptBridge.eval("try { window.CrazyGames.SDK.game.loadingStop(); } catch(e) {}", true)


# Analytics — chama window.CrazyGames.SDK.analytics.trackEvent.
# Em editor / sem SDK, loga no console pra debug.
func track_event(event_name: String, properties: Dictionary = {}) -> void:
	var props_str: String = JSON.stringify(properties)
	if not _sdk_available:
		print("Analytics: %s %s" % [event_name, props_str])
		return
	var name_str: String = JSON.stringify(event_name)
	var code: String = """
		try {
			if (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.analytics) {
				window.CrazyGames.SDK.analytics.trackEvent(%s, %s);
			}
		} catch(e) { console.warn('analytics track failed:', e); }
	""" % [name_str, props_str]
	JavaScriptBridge.eval(code, true)


func _on_ad_success_internal(_args = []) -> void:
	_ad_in_progress = false
	var cb: Callable = _on_success
	_on_success = Callable()
	_on_fail = Callable()
	if cb.is_valid():
		cb.call()


func _on_ad_fail_internal(_args = []) -> void:
	_ad_in_progress = false
	var cb: Callable = _on_fail
	_on_success = Callable()
	_on_fail = Callable()
	if cb.is_valid():
		cb.call()
