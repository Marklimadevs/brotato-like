extends Node

# AdsManager — autoload singleton.
# Ponte com o SDK do CrazyGames v3 via JavaScriptBridge.
#
# Fluxo:
#   1. _ready espera o <script> do SDK carregar (retry até 2s)
#   2. Chama window.CrazyGames.SDK.init() — Promise async
#   3. Quando o Promise resolve → _sdk_available = true e podemos pedir ads
#
# Em editor (F5) ou fora da web: simula sucesso após 1.2s pra você ver
# o "Carregando anúncio..." e ter sensação de tempo de ad.
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
var _sdk_ready_cb = null
var _sdk_failed_cb = null


func _ready() -> void:
	if not OS.has_feature("web"):
		print("AdsManager: rodando fora da web — modo dev (ads simulados).")
		return

	# Setup callbacks ANTES de qualquer chamada de SDK
	_setup_callbacks()

	# Aguarda 1 frame pro DOM estabilizar
	await get_tree().process_frame

	# Detecta SDK com retry (script tag é async, pode não ter carregado ainda)
	var detected: bool = false
	for i in range(20):  # até 2s (20 × 0.1s)
		var has_sdk = JavaScriptBridge.eval(
			"typeof window.CrazyGames !== 'undefined' && typeof window.CrazyGames.SDK !== 'undefined'",
			true
		)
		if has_sdk == true:
			detected = true
			break
		await get_tree().create_timer(0.1).timeout

	if not detected:
		print("AdsManager: SDK do CrazyGames não detectado após 2s — modo simulado (provavelmente rodando localmente ou fora do iframe deles).")
		return

	print("AdsManager: SDK detectado, chamando init()...")

	# Chama SDK.init() — assíncrono. _on_sdk_ready_internal seta _sdk_available
	# quando o Promise resolve. Se init() não existir (SDK velho), assume pronto.
	JavaScriptBridge.eval("""
		try {
			console.log('[AdsManager] CrazyGames SDK encontrado, chamando init()');
			if (window.CrazyGames.SDK.init) {
				window.CrazyGames.SDK.init()
					.then(function() {
						console.log('[AdsManager] SDK.init() resolveu OK');
						if (window.godotSdkReady) window.godotSdkReady();
					})
					.catch(function(err) {
						console.error('[AdsManager] SDK.init() falhou:', err);
						if (window.godotSdkFailed) window.godotSdkFailed();
					});
			} else {
				console.log('[AdsManager] SDK sem método init — assumindo pronto');
				if (window.godotSdkReady) window.godotSdkReady();
			}
		} catch(e) {
			console.error('[AdsManager] erro chamando init:', e);
			if (window.godotSdkFailed) window.godotSdkFailed();
		}
	""", true)


func _setup_callbacks() -> void:
	_success_cb = JavaScriptBridge.create_callback(_on_ad_success_internal)
	_fail_cb = JavaScriptBridge.create_callback(_on_ad_fail_internal)
	_sdk_ready_cb = JavaScriptBridge.create_callback(_on_sdk_ready_internal)
	_sdk_failed_cb = JavaScriptBridge.create_callback(_on_sdk_failed_internal)
	var window = JavaScriptBridge.get_interface("window")
	if window != null:
		window.godotAdSuccess = _success_cb
		window.godotAdFail = _fail_cb
		window.godotSdkReady = _sdk_ready_cb
		window.godotSdkFailed = _sdk_failed_cb


func _on_sdk_ready_internal(_args = []) -> void:
	_sdk_available = true
	print("AdsManager: ✓ SDK pronto, ads habilitados")


func _on_sdk_failed_internal(_args = []) -> void:
	_sdk_available = false
	print("AdsManager: ✗ SDK falhou no init — modo simulado")


func is_real_sdk_available() -> bool:
	return _sdk_available


func is_ad_in_progress() -> bool:
	return _ad_in_progress


# Pede um rewarded ad. Sempre retorna por callback (assíncrono).
# Em editor / sem SDK, simula sucesso após delay perceptível.
func request_rewarded_ad(on_success: Callable, on_fail: Callable) -> void:
	if _ad_in_progress:
		on_fail.call()
		return
	_ad_in_progress = true
	_on_success = on_success
	_on_fail = on_fail

	if not _sdk_available:
		# Editor / sem SDK — simula sucesso após delay (pra UX feel)
		print("AdsManager: simulando rewarded ad (SDK indisponível)")
		await get_tree().create_timer(1.5).timeout
		_on_ad_success_internal([])
		return

	# Produção — chama o SDK do CrazyGames
	print("AdsManager: requestAd('rewarded')...")
	JavaScriptBridge.eval("""
		try {
			window.CrazyGames.SDK.ad.requestAd('rewarded')
				.then(function() {
					console.log('[AdsManager] ad concluído');
					window.godotAdSuccess();
				})
				.catch(function(err) {
					console.warn('[AdsManager] ad falhou/pulado:', err);
					window.godotAdFail();
				});
		} catch(e) {
			console.error('[AdsManager] erro requestAd:', e);
			window.godotAdFail();
		}
	""", true)


# Notificações de gameplay state pro CrazyGames decidir quando mostrar ads.
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
