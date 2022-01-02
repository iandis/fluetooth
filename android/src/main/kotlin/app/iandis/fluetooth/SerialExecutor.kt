package app.iandis.fluetooth

import java.util.*
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.concurrent.ExecutorService

class SerialExecutor : Executor {
    private val _executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val _tasks: Queue<Runnable> = ArrayDeque()
    private var _active: Runnable? = null

    @Synchronized
    override fun execute(r: Runnable) {
        _tasks.add(Runnable {
            try {
                r.run()
            } finally {
                _scheduleNext()
            }
        })
        if (_active == null) {
            _scheduleNext()
        }
    }

    @Synchronized
    private fun _scheduleNext() {
        _active = _tasks.poll()
        if (_active != null) {
            _executor.execute(_active);
        }
    }

    fun shutdown() {
        _tasks.clear()
        _active = null
        _executor.shutdown()
    }

}